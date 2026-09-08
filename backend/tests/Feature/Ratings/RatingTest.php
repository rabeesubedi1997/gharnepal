<?php

namespace Tests\Feature\Ratings;

use App\Models\Municipality;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\Rating;
use App\Models\Role;
use App\Models\User;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RatingTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    /** @return array{0: PropertyListing, 1: User} */
    private function publishedListing(): array
    {
        $owner = User::factory()->create();
        $municipality = Municipality::where('code', 'M-KTM')->firstOrFail();
        $ward = Ward::where('municipality_id', $municipality->id)->where('ward_number', 1)->firstOrFail();

        $property = Property::create([
            'owner_user_id' => $owner->id,
            'created_by' => $owner->id,
            'property_type' => 'apartment',
            'bedrooms' => 2,
            'total_area_sqm' => 90,
        ]);
        $property->address()->create([
            'province_id' => $municipality->district->province_id,
            'district_id' => $municipality->district_id,
            'municipality_id' => $municipality->id,
            'ward_id' => $ward->id,
        ]);
        $property->managers()->attach($owner->id, ['relation' => 'owner']);

        $listing = $property->listings()->create([
            'purpose' => 'rent',
            'price' => 20000,
            'price_period' => 'monthly',
            'title' => 'Rating test listing ' . uniqid(),
            'slug' => 'rating-test-listing-' . uniqid(),
            'status' => PropertyListing::STATUS_PUBLISHED,
            'published_at' => now(),
            'created_by' => $owner->id,
        ]);

        return [$listing, $owner];
    }

    private function admin(): User
    {
        $admin = User::factory()->create();
        $admin->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']));

        return $admin;
    }

    public function test_a_user_can_submit_a_rating_and_it_appears_on_the_listing(): void
    {
        [$listing] = $this->publishedListing();
        $rater = User::factory()->create();

        $response = $this->actingAs($rater, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/ratings", [
            'score' => 4,
            'comment' => 'Nice place, responsive owner.',
        ]);

        $response->assertCreated()->assertJsonPath('data.score', 4);

        $detail = $this->getJson("/api/v1/listings/{$listing->slug}");
        $detail->assertOk()
            ->assertJsonPath('data.rating.average', 4)
            ->assertJsonPath('data.rating.count', 1);
    }

    public function test_submitting_a_rating_twice_updates_it_instead_of_duplicating(): void
    {
        [$listing] = $this->publishedListing();
        $rater = User::factory()->create();

        $this->actingAs($rater, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/ratings", ['score' => 3]);
        $this->actingAs($rater, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/ratings", ['score' => 5])
            ->assertOk()
            ->assertJsonPath('data.score', 5);

        $this->assertSame(1, Rating::where('user_id', $rater->id)->count());
    }

    public function test_an_owner_cannot_rate_their_own_listing(): void
    {
        [$listing, $owner] = $this->publishedListing();

        $this->actingAs($owner, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/ratings", [
            'score' => 5,
        ])->assertUnprocessable();
    }

    public function test_guests_cannot_submit_a_rating(): void
    {
        [$listing] = $this->publishedListing();

        $this->postJson("/api/v1/listings/{$listing->id}/ratings", ['score' => 5])->assertUnauthorized();
    }

    public function test_a_score_outside_one_to_five_is_rejected(): void
    {
        [$listing] = $this->publishedListing();
        $rater = User::factory()->create();

        $this->actingAs($rater, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/ratings", ['score' => 6])
            ->assertUnprocessable();
    }

    public function test_a_user_can_remove_their_own_rating(): void
    {
        [$listing] = $this->publishedListing();
        $rater = User::factory()->create();
        $this->actingAs($rater, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/ratings", ['score' => 4]);

        $this->actingAs($rater, 'sanctum')->deleteJson("/api/v1/listings/{$listing->id}/ratings")->assertNoContent();

        $this->assertDatabaseCount('ratings', 0);
    }

    public function test_ratings_list_is_public_and_paginated(): void
    {
        [$listing] = $this->publishedListing();
        $rater = User::factory()->create(['name' => 'Rater One']);
        $this->actingAs($rater, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/ratings", [
            'score' => 5,
            'comment' => 'Great!',
        ]);

        $response = $this->getJson("/api/v1/listings/{$listing->id}/ratings");

        $response->assertOk()
            ->assertJsonPath('data.0.score', 5)
            ->assertJsonPath('data.0.user.name', 'Rater One');
    }

    public function test_my_rating_is_correct_for_a_bearer_token_client(): void
    {
        // Deliberately not actingAs(): that helper calls Auth::shouldUse()
        // itself, which would mask the real bug — GET /listings/{slug}
        // carries no auth:sanctum middleware, so nothing switches the
        // request's default guard for a real HTTP request. A genuine
        // bearer-token request is the only way to catch it.
        [$listing] = $this->publishedListing();
        $rater = User::factory()->create();
        $token = $rater->createToken('test')->plainTextToken;

        $this->actingAs($rater, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/ratings", [
            'score' => 4,
            'comment' => 'Nice place.',
        ]);

        $detail = $this->withHeader('Authorization', "Bearer {$token}")->getJson("/api/v1/listings/{$listing->slug}");

        $detail->assertOk()
            ->assertJsonPath('data.my_rating.score', 4)
            ->assertJsonPath('data.my_rating.comment', 'Nice place.');
    }

    public function test_admin_can_hide_and_unhide_a_rating(): void
    {
        [$listing] = $this->publishedListing();
        $rater = User::factory()->create();
        $create = $this->actingAs($rater, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/ratings", ['score' => 1, 'comment' => 'Spammy']);
        $ratingId = $create->json('data.id');

        $admin = $this->admin();
        $this->actingAs($admin, 'sanctum')->patchJson("/api/v1/admin/ratings/{$ratingId}/hide")
            ->assertOk()->assertJsonPath('data.status', 'hidden');

        // Hidden ratings no longer count toward the public average/list.
        $this->getJson("/api/v1/listings/{$listing->id}/ratings")->assertJsonCount(0, 'data');
        $this->getJson("/api/v1/listings/{$listing->slug}")->assertJsonPath('data.rating.count', 0);

        $this->actingAs($admin, 'sanctum')->patchJson("/api/v1/admin/ratings/{$ratingId}/unhide")
            ->assertOk()->assertJsonPath('data.status', 'visible');
        $this->getJson("/api/v1/listings/{$listing->id}/ratings")->assertJsonCount(1, 'data');
    }

    public function test_a_non_admin_cannot_moderate_ratings(): void
    {
        [$listing] = $this->publishedListing();
        $rater = User::factory()->create();
        $create = $this->actingAs($rater, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/ratings", ['score' => 2]);

        $this->actingAs($rater, 'sanctum')->getJson('/api/v1/admin/ratings')->assertForbidden();
        $this->actingAs($rater, 'sanctum')->patchJson("/api/v1/admin/ratings/{$create->json('data.id')}/hide")->assertForbidden();
    }
}
