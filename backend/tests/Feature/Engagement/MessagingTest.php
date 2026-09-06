<?php

namespace Tests\Feature\Engagement;

use App\Models\User;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
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
}
