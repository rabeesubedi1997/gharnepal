<?php

namespace Tests\Feature\Engagement;

use App\Models\Agency;
use App\Models\User;
use App\Notifications\NewMessageNotification;
use App\Notifications\ViewingRequestReceivedNotification;
use App\Notifications\ViewingRequestUpdatedNotification;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

/**
 * "Basic agency lead-routing" from the competitive-benchmark roadmap: a
 * viewing request or first-contact message is a lead, and previously it
 * only ever reached the one specific user who happened to own the listing
 * — even when that person belonged to an agency with other members who
 * could've picked it up. See LeadRoutingService.
 */
class LeadRoutingTest extends TestCase
{
    use RefreshDatabase, CreatesListings;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    public function test_a_viewing_request_notifies_a_solo_owner_same_as_before(): void
    {
        Notification::fake();

        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);
        $buyer = User::factory()->create();

        $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/viewing-requests', [
            'listing_id' => $listing->id,
            'proposed_datetime' => now()->addDays(2)->toIso8601String(),
        ])->assertCreated();

        Notification::assertSentTo($owner, ViewingRequestReceivedNotification::class);
    }

    public function test_a_viewing_request_for_an_agency_listing_notifies_every_agency_member(): void
    {
        Notification::fake();

        $agency = Agency::create(['name' => 'Team Realty', 'slug' => 'team-realty-'.uniqid(), 'status' => 'active', 'verified_at' => now()]);
        $listingAgent = User::factory()->create(['name' => 'Listing Agent']);
        $teammate = User::factory()->create(['name' => 'Teammate Agent']);
        $agency->members()->attach([$listingAgent->id, $teammate->id], ['role_in_agency' => 'agent']);

        $listing = $this->publishedListing($listingAgent);
        $buyer = User::factory()->create();

        $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/viewing-requests', [
            'listing_id' => $listing->id,
            'proposed_datetime' => now()->addDays(2)->toIso8601String(),
        ])->assertCreated();

        Notification::assertSentTo($listingAgent, ViewingRequestReceivedNotification::class);
        Notification::assertSentTo($teammate, ViewingRequestReceivedNotification::class);
    }

    public function test_a_viewing_request_for_an_unverified_agencys_listing_only_notifies_the_owner(): void
    {
        Notification::fake();

        $agency = Agency::create(['name' => 'Pending Realty', 'slug' => 'pending-realty-'.uniqid(), 'status' => 'pending', 'verified_at' => null]);
        $listingAgent = User::factory()->create();
        $teammate = User::factory()->create();
        $agency->members()->attach([$listingAgent->id, $teammate->id], ['role_in_agency' => 'agent']);

        $listing = $this->publishedListing($listingAgent);
        $buyer = User::factory()->create();

        $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/viewing-requests', [
            'listing_id' => $listing->id,
            'proposed_datetime' => now()->addDays(2)->toIso8601String(),
        ])->assertCreated();

        Notification::assertSentTo($listingAgent, ViewingRequestReceivedNotification::class);
        Notification::assertNotSentTo($teammate, ViewingRequestReceivedNotification::class);
    }

    public function test_confirming_a_viewing_request_notifies_only_the_requester_not_the_whole_agency(): void
    {
        $agency = Agency::create(['name' => 'Confirm Realty', 'slug' => 'confirm-realty-'.uniqid(), 'status' => 'active', 'verified_at' => now()]);
        $listingAgent = User::factory()->create();
        $teammate = User::factory()->create();
        $agency->members()->attach([$listingAgent->id, $teammate->id], ['role_in_agency' => 'agent']);

        $listing = $this->publishedListing($listingAgent);
        $buyer = User::factory()->create();

        $create = $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/viewing-requests', [
            'listing_id' => $listing->id,
            'proposed_datetime' => now()->addDays(2)->toIso8601String(),
        ]);
        $id = $create->json('data.id');

        Notification::fake(); // only assert on what confirm() itself sends

        $this->actingAs($listingAgent, 'sanctum')
            ->patchJson("/api/v1/viewing-requests/{$id}/transition", ['action' => 'confirm'])
            ->assertOk();

        Notification::assertSentTo($buyer, ViewingRequestUpdatedNotification::class);
        Notification::assertNotSentTo($teammate, ViewingRequestUpdatedNotification::class);
        Notification::assertNotSentTo($listingAgent, ViewingRequestUpdatedNotification::class);
    }

    public function test_a_new_conversation_on_an_agency_listing_notifies_every_agency_member(): void
    {
        Notification::fake();

        $agency = Agency::create(['name' => 'Message Realty', 'slug' => 'message-realty-'.uniqid(), 'status' => 'active', 'verified_at' => now()]);
        $listingAgent = User::factory()->create();
        $teammate = User::factory()->create();
        $agency->members()->attach([$listingAgent->id, $teammate->id], ['role_in_agency' => 'agent']);

        $listing = $this->publishedListing($listingAgent);
        $buyer = User::factory()->create();

        $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/conversations', [
            'listing_id' => $listing->id,
            'message' => 'Hi, is this still available?',
        ])->assertCreated();

        Notification::assertSentTo($listingAgent, NewMessageNotification::class);
        Notification::assertSentTo($teammate, NewMessageNotification::class);
    }

    public function test_a_reply_in_an_existing_conversation_does_not_re_notify_the_whole_agency(): void
    {
        $agency = Agency::create(['name' => 'Reply Realty', 'slug' => 'reply-realty-'.uniqid(), 'status' => 'active', 'verified_at' => now()]);
        $listingAgent = User::factory()->create();
        $teammate = User::factory()->create();
        $agency->members()->attach([$listingAgent->id, $teammate->id], ['role_in_agency' => 'agent']);

        $listing = $this->publishedListing($listingAgent);
        $buyer = User::factory()->create();

        $start = $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/conversations', [
            'listing_id' => $listing->id,
            'message' => 'Hi, is this still available?',
        ]);
        $conversationId = $start->json('data.id');

        Notification::fake(); // only assert on the reply, not the opening message

        $this->actingAs($listingAgent, 'sanctum')->postJson("/api/v1/conversations/{$conversationId}/messages", [
            'body' => 'Yes, still available!',
        ])->assertCreated();

        Notification::assertSentTo($buyer, NewMessageNotification::class);
        Notification::assertNotSentTo($teammate, NewMessageNotification::class);
    }
}
