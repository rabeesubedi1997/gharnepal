<?php

namespace Tests\Feature\Engagement;

use App\Models\PropertyRequest;
use App\Models\Role;
use App\Models\User;
use App\Notifications\NewMessageNotification;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class MessagingTest extends TestCase
{
    use RefreshDatabase, CreatesListings;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    public function test_a_buyer_can_start_a_conversation_and_the_owner_can_reply(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);
        $buyer = User::factory()->create();

        $start = $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/conversations', [
            'listing_id' => $listing->id,
            'message' => 'Is this still available?',
        ]);
        $start->assertCreated();
        $conversationId = $start->json('data.id');

        $this->assertDatabaseHas('messages', ['conversation_id' => $conversationId, 'body' => 'Is this still available?']);

        $reply = $this->actingAs($owner, 'sanctum')->postJson("/api/v1/conversations/{$conversationId}/messages", [
            'body' => 'Yes, still available!',
        ]);
        $reply->assertCreated();

        $show = $this->actingAs($buyer, 'sanctum')->getJson("/api/v1/conversations/{$conversationId}");
        $show->assertOk()->assertJsonCount(2, 'data.messages');
    }

    public function test_a_reply_notifies_only_the_other_participant_not_the_sender(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);
        $buyer = User::factory()->create();

        Notification::fake();
        $conversationId = $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/conversations', [
            'listing_id' => $listing->id,
            'message' => 'Is this still available?',
        ])->json('data.id');

        Notification::assertSentTo($owner, NewMessageNotification::class);
        Notification::assertNotSentTo($buyer, NewMessageNotification::class);

        Notification::fake();
        $this->actingAs($owner, 'sanctum')->postJson("/api/v1/conversations/{$conversationId}/messages", [
            'body' => 'Yes, still available!',
        ]);

        Notification::assertSentTo($buyer, NewMessageNotification::class);
        Notification::assertNotSentTo($owner, NewMessageNotification::class);
    }

    public function test_an_admin_who_is_a_genuine_participant_is_not_flagged_as_support(): void
    {
        // A user who happens to hold the admin role but is chatting through
        // their own real buyer/owner account should look like any other
        // participant — "is_from_support" means "stepped in from outside",
        // not "this account has the admin role".
        $adminBuyer = User::factory()->create();
        $adminBuyer->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']));
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);

        $conversationId = $this->actingAs($adminBuyer, 'sanctum')->postJson('/api/v1/conversations', [
            'listing_id' => $listing->id,
            'message' => 'Hi, is this still available?',
        ])->json('data.id');

        $show = $this->actingAs($adminBuyer, 'sanctum')->getJson("/api/v1/conversations/{$conversationId}");
        $show->assertOk()->assertJsonPath('data.messages.0.is_from_support', false);
    }

    public function test_contacting_the_same_listing_twice_reuses_the_thread(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);
        $buyer = User::factory()->create();

        $first = $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/conversations', [
            'listing_id' => $listing->id,
            'message' => 'Hello',
        ]);
        $second = $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/conversations', [
            'listing_id' => $listing->id,
            'message' => 'Following up',
        ]);

        $this->assertEquals($first->json('data.id'), $second->json('data.id'));
        $this->assertDatabaseCount('conversations', 1);
    }

    public function test_a_stranger_cannot_read_someone_elses_conversation(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);
        $buyer = User::factory()->create();

        $start = $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/conversations', [
            'listing_id' => $listing->id,
            'message' => 'Hi',
        ]);

        $stranger = User::factory()->create();
        $this->actingAs($stranger, 'sanctum')
            ->getJson('/api/v1/conversations/' . $start->json('data.id'))
            ->assertForbidden();
    }

    public function test_owner_cannot_message_themselves_about_their_own_listing(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);

        $this->actingAs($owner, 'sanctum')->postJson('/api/v1/conversations', [
            'listing_id' => $listing->id,
            'message' => 'Hello me',
        ])->assertUnprocessable();
    }

    public function test_an_owner_can_respond_to_a_property_request(): void
    {
        $requester = User::factory()->create();
        $propertyRequest = PropertyRequest::create(['user_id' => $requester->id, 'purpose' => 'rent', 'status' => 'open']);
        $responder = User::factory()->create();

        $start = $this->actingAs($responder, 'sanctum')->postJson('/api/v1/conversations', [
            'property_request_id' => $propertyRequest->id,
            'message' => 'I have a 2BHK matching what you need.',
        ]);

        $start->assertCreated()
            ->assertJsonPath('data.listing', null)
            ->assertJsonPath('data.property_request.id', $propertyRequest->id)
            ->assertJsonPath('data.other_participant.id', $requester->id);

        $this->assertDatabaseHas('messages', [
            'conversation_id' => $start->json('data.id'),
            'body' => 'I have a 2BHK matching what you need.',
        ]);
    }

    public function test_responding_to_the_same_request_twice_reuses_the_thread(): void
    {
        $requester = User::factory()->create();
        $propertyRequest = PropertyRequest::create(['user_id' => $requester->id, 'purpose' => 'rent', 'status' => 'open']);
        $responder = User::factory()->create();

        $first = $this->actingAs($responder, 'sanctum')->postJson('/api/v1/conversations', [
            'property_request_id' => $propertyRequest->id,
            'message' => 'Hello',
        ]);
        $second = $this->actingAs($responder, 'sanctum')->postJson('/api/v1/conversations', [
            'property_request_id' => $propertyRequest->id,
            'message' => 'Following up',
        ]);

        $this->assertEquals($first->json('data.id'), $second->json('data.id'));
        $this->assertDatabaseCount('conversations', 1);
    }

    public function test_a_requester_cannot_respond_to_their_own_request(): void
    {
        $requester = User::factory()->create();
        $propertyRequest = PropertyRequest::create(['user_id' => $requester->id, 'purpose' => 'rent', 'status' => 'open']);

        $this->actingAs($requester, 'sanctum')->postJson('/api/v1/conversations', [
            'property_request_id' => $propertyRequest->id,
            'message' => 'Hello me',
        ])->assertUnprocessable();
    }
}
