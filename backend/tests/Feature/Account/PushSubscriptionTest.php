<?php

namespace Tests\Feature\Account;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PushSubscriptionTest extends TestCase
{
    use RefreshDatabase;

    private function subscriptionPayload(string $endpoint = 'https://fcm.googleapis.com/fcm/send/test-endpoint'): array
    {
        return [
            'endpoint' => $endpoint,
            'keys' => ['p256dh' => 'fake-p256dh-key', 'auth' => 'fake-auth-secret'],
        ];
    }

    public function test_the_vapid_public_key_is_publicly_readable(): void
    {
        config(['services.web_push.vapid_public_key' => 'test-public-key']);

        $this->getJson('/api/v1/push/vapid-public-key')
            ->assertOk()
            ->assertJsonPath('key', 'test-public-key');
    }

    public function test_a_user_can_subscribe_to_push(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/account/push-subscriptions', $this->subscriptionPayload())
            ->assertCreated();

        $this->assertDatabaseCount('push_subscriptions', 1);
        $this->assertDatabaseHas('push_subscriptions', ['user_id' => $user->id, 'p256dh' => 'fake-p256dh-key']);
    }

    public function test_resubscribing_the_same_endpoint_updates_rather_than_duplicates(): void
    {
        $user = User::factory()->create();
        $endpoint = 'https://fcm.googleapis.com/fcm/send/same-endpoint';

        $this->actingAs($user, 'sanctum')->postJson('/api/v1/account/push-subscriptions', $this->subscriptionPayload($endpoint))->assertCreated();
        $this->actingAs($user, 'sanctum')->postJson('/api/v1/account/push-subscriptions', [
            'endpoint' => $endpoint,
            'keys' => ['p256dh' => 'rotated-key', 'auth' => 'rotated-secret'],
        ])->assertCreated();

        $this->assertDatabaseCount('push_subscriptions', 1);
        $this->assertDatabaseHas('push_subscriptions', ['user_id' => $user->id, 'p256dh' => 'rotated-key']);
    }

    public function test_a_user_can_unsubscribe(): void
    {
        $user = User::factory()->create();
        $endpoint = 'https://fcm.googleapis.com/fcm/send/to-remove';

        $this->actingAs($user, 'sanctum')->postJson('/api/v1/account/push-subscriptions', $this->subscriptionPayload($endpoint))->assertCreated();

        $this->actingAs($user, 'sanctum')
            ->deleteJson('/api/v1/account/push-subscriptions', ['endpoint' => $endpoint])
            ->assertNoContent();

        $this->assertDatabaseCount('push_subscriptions', 0);
    }

    public function test_guests_cannot_subscribe(): void
    {
        $this->postJson('/api/v1/account/push-subscriptions', $this->subscriptionPayload())->assertUnauthorized();
    }
}
