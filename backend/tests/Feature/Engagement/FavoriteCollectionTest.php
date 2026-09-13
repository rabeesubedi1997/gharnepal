<?php

namespace Tests\Feature\Engagement;

use App\Models\Favorite;
use App\Models\FavoriteCollection;
use App\Models\User;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FavoriteCollectionTest extends TestCase
{
    use RefreshDatabase, CreatesListings;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    public function test_a_user_can_create_a_collection_and_save_a_listing_into_it(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);
        $buyer = User::factory()->create();

        $create = $this->actingAs($buyer, 'sanctum')
            ->postJson('/api/v1/account/favorite-collections', ['name' => 'Family homes']);
        $create->assertCreated()->assertJsonPath('data.name', 'Family homes');
        $collectionId = $create->json('data.id');

        $this->actingAs($buyer, 'sanctum')
            ->postJson('/api/v1/account/favorites', ['listing_id' => $listing->id, 'collection_id' => $collectionId])
            ->assertCreated();

        $this->assertDatabaseHas('favorites', [
            'user_id' => $buyer->id,
            'property_listing_id' => $listing->id,
            'favorite_collection_id' => $collectionId,
        ]);

        $this->actingAs($buyer, 'sanctum')
            ->getJson("/api/v1/account/favorites?collection_id={$collectionId}")
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    public function test_a_user_cannot_save_into_someone_elses_collection(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);
        $buyer = User::factory()->create();
        $stranger = User::factory()->create();
        $othersCollection = FavoriteCollection::create(['user_id' => $stranger->id, 'name' => 'Not yours']);

        $this->actingAs($buyer, 'sanctum')
            ->postJson('/api/v1/account/favorites', ['listing_id' => $listing->id, 'collection_id' => $othersCollection->id])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['collection_id']);
    }

    public function test_a_user_can_move_an_already_saved_listing_into_a_collection(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);
        $buyer = User::factory()->create();
        $collection = FavoriteCollection::create(['user_id' => $buyer->id, 'name' => 'Shortlist']);

        Favorite::create(['user_id' => $buyer->id, 'property_listing_id' => $listing->id]);

        $this->actingAs($buyer, 'sanctum')
            ->putJson("/api/v1/account/favorites/{$listing->id}", ['collection_id' => $collection->id])
            ->assertOk();

        $this->assertDatabaseHas('favorites', [
            'user_id' => $buyer->id,
            'property_listing_id' => $listing->id,
            'favorite_collection_id' => $collection->id,
        ]);
    }

    public function test_deleting_a_collection_keeps_the_favorites_but_uncollects_them(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);
        $buyer = User::factory()->create();
        $collection = FavoriteCollection::create(['user_id' => $buyer->id, 'name' => 'Temp']);
        $favorite = Favorite::create([
            'user_id' => $buyer->id,
            'property_listing_id' => $listing->id,
            'favorite_collection_id' => $collection->id,
        ]);

        $this->actingAs($buyer, 'sanctum')
            ->deleteJson("/api/v1/account/favorite-collections/{$collection->id}")
            ->assertOk();

        $this->assertDatabaseHas('favorites', ['id' => $favorite->id, 'favorite_collection_id' => null]);
        $this->assertDatabaseMissing('favorite_collections', ['id' => $collection->id]);
    }

    public function test_a_user_cannot_delete_someone_elses_collection(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        $collection = FavoriteCollection::create(['user_id' => $owner->id, 'name' => 'Mine']);

        $this->actingAs($stranger, 'sanctum')
            ->deleteJson("/api/v1/account/favorite-collections/{$collection->id}")
            ->assertForbidden();

        $this->assertDatabaseHas('favorite_collections', ['id' => $collection->id]);
    }

    public function test_anyone_with_the_share_link_can_view_a_collection_without_logging_in(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);
        $curator = User::factory()->create(['name' => 'Anita Gurung']);
        $collection = FavoriteCollection::create(['user_id' => $curator->id, 'name' => 'Kathmandu shortlist']);
        Favorite::create([
            'user_id' => $curator->id,
            'property_listing_id' => $listing->id,
            'favorite_collection_id' => $collection->id,
        ]);

        $response = $this->getJson("/api/v1/collections/{$collection->share_token}");

        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('collection.name', 'Kathmandu shortlist')
            ->assertJsonPath('collection.curated_by', 'Anita Gurung');
    }

    public function test_an_unpublished_listing_never_appears_on_a_shared_collection(): void
    {
        $curator = User::factory()->create();
        $collection = FavoriteCollection::create(['user_id' => $curator->id, 'name' => 'Drafts']);
        $draft = $this->draftListing($curator);
        Favorite::create([
            'user_id' => $curator->id,
            'property_listing_id' => $draft->id,
            'favorite_collection_id' => $collection->id,
        ]);

        $this->getJson("/api/v1/collections/{$collection->share_token}")
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }

    public function test_an_unknown_share_token_returns_404(): void
    {
        $this->getJson('/api/v1/collections/does-not-exist')->assertNotFound();
    }
}
