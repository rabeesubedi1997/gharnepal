<?php

namespace Tests\Feature\Engagement;

use App\Models\User;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FavoriteTest extends TestCase
{
    use RefreshDatabase, CreatesListings;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    public function test_a_user_can_favorite_and_unfavorite_a_listing(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);
        $buyer = User::factory()->create();

        $this->actingAs($buyer, 'sanctum')
            ->postJson('/api/v1/account/favorites', ['listing_id' => $listing->id])
            ->assertCreated();

        $this->assertDatabaseHas('favorites', ['user_id' => $buyer->id, 'property_listing_id' => $listing->id]);

        $index = $this->actingAs($buyer, 'sanctum')->getJson('/api/v1/account/favorites');
        $index->assertOk()->assertJsonCount(1, 'data');

        $this->actingAs($buyer, 'sanctum')
            ->deleteJson("/api/v1/account/favorites/{$listing->id}")
            ->assertOk();

        $this->assertDatabaseMissing('favorites', ['user_id' => $buyer->id, 'property_listing_id' => $listing->id]);
    }

    public function test_favoriting_the_same_listing_twice_is_idempotent(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);
        $buyer = User::factory()->create();

        $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/account/favorites', ['listing_id' => $listing->id]);
        $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/account/favorites', ['listing_id' => $listing->id]);

        $this->assertEquals(1, \App\Models\Favorite::where('user_id', $buyer->id)->count());
    }
}
