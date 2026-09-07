<?php

namespace Tests\Feature\Engagement;

use App\Models\Role;
use App\Models\User;
use App\Notifications\NewMessageNotification;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class AdminConversationModerationTest extends TestCase
{
    use RefreshDatabase, CreatesListings;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    private function admin(): User
    {
        $admin = User::factory()->create();
        $admin->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']));

        return $admin;
    }

    public function test_admin_can_list_and_read_conversations_for_moderation(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);
        $buyer = User::factory()->create();

        $start = $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/conversations', [
            'listing_id' => $listing->id,
            'message' => 'Is this still available?',
        ]);
        $conversationId = $start->json('data.id');

        $admin = $this->admin();

        $index = $this->actingAs($admin, 'sanctum')->getJson('/api/v1/admin/conversations');
        $index->assertOk()->assertJsonPath('data.0.id', $conversationId);
        $index->assertJsonPath('data.0.buyer.id', $buyer->id);
        $index->assertJsonPath('data.0.owner.id', $owner->id);

        $show = $this->actingAs($admin, 'sanctum')->getJson("/api/v1/admin/conversations/{$conversationId}");
        $show->assertOk()->assertJsonCount(1, 'data.messages');
        $show->assertJsonPath('data.messages.0.body', 'Is this still available?');
    }

    public function test_a_non_admin_cannot_read_the_moderation_queue(): void
    {
        $buyer = User::factory()->create();

        $this->actingAs($buyer, 'sanctum')->getJson('/api/v1/admin/conversations')->assertForbidden();
    }

    public function test_admin_can_reply_into_a_conversation_and_both_participants_are_notified(): void
    {
        Notification::fake();

        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);
        $buyer = User::factory()->create();

        $start = $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/conversations', [
            'listing_id' => $listing->id,
            'message' => 'Is this still available?',
        ]);
        $conversationId = $start->json('data.id');

        $admin = $this->admin();
        Notification::fake(); // reset — the buyer's own opening message already queued one

        $reply = $this->actingAs($admin, 'sanctum')->postJson("/api/v1/admin/conversations/{$conversationId}/messages", [
            'body' => "We're looking into your report on this listing.",
        ]);

        $reply->assertCreated()->assertJsonPath('data.sender.id', $admin->id);

        Notification::assertSentTo($buyer, NewMessageNotification::class);
        Notification::assertSentTo($owner, NewMessageNotification::class);

        // The regular participant-facing view flags it as a support message,
        // not a message from the other party.
        $show = $this->actingAs($buyer, 'sanctum')->getJson("/api/v1/conversations/{$conversationId}");
        $show->assertOk()->assertJsonPath('data.messages.1.is_from_support', true);
    }

    public function test_a_non_admin_cannot_send_a_moderation_reply(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);
        $buyer = User::factory()->create();

        $start = $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/conversations', [
            'listing_id' => $listing->id,
            'message' => 'Is this still available?',
        ]);
        $conversationId = $start->json('data.id');

        $outsider = User::factory()->create();
        $this->actingAs($outsider, 'sanctum')
            ->postJson("/api/v1/admin/conversations/{$conversationId}/messages", ['body' => 'Hi'])
            ->assertForbidden();
    }
}
