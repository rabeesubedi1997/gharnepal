<?php

namespace Tests\Feature\Engagement;

use App\Models\User;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ViewingRequestTest extends TestCase
{
    use RefreshDatabase, CreatesListings;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    public function test_full_viewing_request_lifecycle_with_visit_verification(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);
        $buyer = User::factory()->create();

        $request = $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/viewing-requests', [
            'listing_id' => $listing->id,
            'proposed_datetime' => now()->addDays(2)->toIso8601String(),
        ]);
        $request->assertCreated()->assertJsonPath('data.status', 'requested');
        $id = $request->json('data.id');

        // only the host can confirm
        $this->actingAs($buyer, 'sanctum')
            ->patchJson("/api/v1/viewing-requests/{$id}/transition", ['action' => 'confirm'])
            ->assertUnprocessable();

        $this->actingAs($owner, 'sanctum')
            ->patchJson("/api/v1/viewing-requests/{$id}/transition", ['action' => 'confirm'])
            ->assertOk()->assertJsonPath('data.status', 'confirmed');

        $this->actingAs($owner, 'sanctum')
            ->patchJson("/api/v1/viewing-requests/{$id}/transition", ['action' => 'complete'])
            ->assertOk()->assertJsonPath('data.status', 'completed');

        // only the requester can submit visit verification
        $this->actingAs($owner, 'sanctum')
            ->postJson("/api/v1/viewing-requests/{$id}/visit-verification", ['visited' => true])
            ->assertForbidden();

        $verify = $this->actingAs($buyer, 'sanctum')->postJson("/api/v1/viewing-requests/{$id}/visit-verification", [
            'visited' => true,
            'matched_listing' => true,
            'price_accurate' => true,
            'host_attended' => true,
        ]);
        $verify->assertOk()->assertJsonPath('data.visit_verification.visited', true);
    }

    public function test_requester_can_cancel_their_own_request(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);
        $buyer = User::factory()->create();

        $request = $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/viewing-requests', [
            'listing_id' => $listing->id,
            'proposed_datetime' => now()->addDay()->toIso8601String(),
        ]);
        $id = $request->json('data.id');

        $this->actingAs($buyer, 'sanctum')
            ->patchJson("/api/v1/viewing-requests/{$id}/transition", ['action' => 'cancel'])
            ->assertOk()->assertJsonPath('data.status', 'cancelled');
    }

    public function test_cannot_request_a_viewing_of_your_own_listing(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);

        $this->actingAs($owner, 'sanctum')->postJson('/api/v1/viewing-requests', [
            'listing_id' => $listing->id,
            'proposed_datetime' => now()->addDay()->toIso8601String(),
        ])->assertUnprocessable();
    }
}
