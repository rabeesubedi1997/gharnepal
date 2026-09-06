<?php

namespace Tests\Feature\Matching;

use App\Models\Municipality;
use App\Models\Neighborhood;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\User;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SmartMatchTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    private function ward(): Ward
    {
        $municipality = Municipality::where('code', 'M-KTM')->firstOrFail();

        return Ward::where('municipality_id', $municipality->id)->where('ward_number', 1)->firstOrFail();
    }

    /** @return array{0: PropertyListing, 1: Property} */
    private function publishedListing(array $propertyOverrides = [], array $listingOverrides = [], ?Neighborhood $neighborhood = null): array
    {
        $owner = User::factory()->create();
        $ward = $this->ward();

        $property = Property::create(array_merge([
            'owner_user_id' => $owner->id,
            'created_by' => $owner->id,
            'property_type' => 'apartment',
            'bedrooms' => 2,
            'bathrooms' => 1,
            'total_area_sqm' => 80,
        ], $propertyOverrides));

        $property->address()->create([
            'province_id' => $ward->municipality->district->province_id,
            'district_id' => $ward->municipality->district_id,
            'municipality_id' => $ward->municipality_id,
            'ward_id' => $ward->id,
            'neighborhood_id' => $neighborhood?->id,
            'lat' => 27.7172,
            'lng' => 85.3240,
        ]);
        $property->managers()->attach($owner->id, ['relation' => 'owner']);

        $listing = $property->listings()->create(array_merge([
            'purpose' => 'rent',
            'price' => 30000,
            'price_period' => 'monthly',
            'title' => 'Test listing ' . uniqid(),
            'slug' => 'test-listing-' . uniqid(),
            'status' => PropertyListing::STATUS_PUBLISHED,
            'published_at' => now(),
            'created_by' => $owner->id,
        ], $listingOverrides));

        return [$listing, $property];
    }

    public function test_a_user_can_save_preferences_and_receive_ranked_matches(): void
    {
        [$goodFit] = $this->publishedListing(['bedrooms' => 3], ['price' => 28000]);
        [$badFit] = $this->publishedListing(['bedrooms' => 1], ['price' => 90000]);

        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')->putJson('/api/v1/account/match-preferences', [
            'purpose' => 'rent',
            'budget_max' => 35000,
            'min_bedrooms' => 2,
        ]);
        $response->assertSuccessful()->assertJsonPath('data.budget_max', 35000);

        $results = $this->actingAs($user, 'sanctum')->getJson('/api/v1/account/match-results');
        $results->assertOk();

        $byListing = collect($results->json('data'))->keyBy('listing.id');
        $this->assertTrue($byListing->has($goodFit->id));

        $goodScore = $byListing[$goodFit->id]['score'];
        $this->assertGreaterThan(50, $goodScore);
        $this->assertNotEmpty($byListing[$goodFit->id]['reasons']);

        // The over-budget, wrong-bedroom listing still earns partial bedroom
        // credit, so it may appear too — but it must rank well below the fit.
        if ($byListing->has($badFit->id)) {
            $this->assertLessThan($goodScore, $byListing[$badFit->id]['score']);
        }
    }

    public function test_guests_cannot_set_preferences_or_view_matches(): void
    {
        $this->putJson('/api/v1/account/match-preferences', ['budget_max' => 10000])->assertUnauthorized();
        $this->getJson('/api/v1/account/match-results')->assertUnauthorized();
    }

    public function test_refreshing_without_saved_preferences_is_rejected(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')->postJson('/api/v1/account/match-results/refresh')
            ->assertUnprocessable();
    }

    public function test_school_requirement_is_scored_from_neighborhood_pois(): void
    {
        $neighborhoodWithSchool = Neighborhood::create(['ward_id' => $this->ward()->id, 'name' => 'HasSchool']);
        $neighborhoodWithSchool->pois()->create(['poi_type' => 'school', 'name' => 'Local School', 'verified' => true]);
        $neighborhoodWithoutSchool = Neighborhood::create(['ward_id' => $this->ward()->id, 'name' => 'NoSchool']);

        [$withSchool] = $this->publishedListing(neighborhood: $neighborhoodWithSchool);
        [$withoutSchool] = $this->publishedListing(neighborhood: $neighborhoodWithoutSchool);

        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum')->putJson('/api/v1/account/match-preferences', [
            'requires_school_nearby' => true,
        ])->assertSuccessful();

        $results = $this->actingAs($user, 'sanctum')->getJson('/api/v1/account/match-results')->json('data');
        $scores = collect($results)->keyBy('listing.id');

        $this->assertEquals(100, $scores[$withSchool->id]['score']);
        $this->assertArrayNotHasKey($withoutSchool->id, $scores->toArray(), 'a listing with no school nearby should score 0 and be excluded');
    }

    public function test_investment_purpose_scores_from_rental_demand_factor(): void
    {
        $neighborhood = Neighborhood::create(['ward_id' => $this->ward()->id, 'name' => 'InvestZone']);
        $score = $neighborhood->score()->create(['overall_score' => 9, 'source' => 'admin_curated', 'computed_at' => now()]);
        $score->factors()->create(['factor_key' => 'rental_demand', 'score' => 9, 'data_source' => 'admin']);

        [$listing] = $this->publishedListing(neighborhood: $neighborhood);

        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum')->putJson('/api/v1/account/match-preferences', [
            'investment_purpose' => true,
        ])->assertSuccessful();

        $results = $this->actingAs($user, 'sanctum')->getJson('/api/v1/account/match-results')->json('data');
        $result = collect($results)->firstWhere('listing.id', $listing->id);

        $this->assertEquals(90, $result['score']);
        $this->assertStringContainsString('rental demand', strtolower($result['reasons'][0]['explanation']));
    }

    public function test_lifestyle_tag_scores_from_the_matching_neighborhood_factor(): void
    {
        $quietNeighborhood = Neighborhood::create(['ward_id' => $this->ward()->id, 'name' => 'QuietZone']);
        $score = $quietNeighborhood->score()->create(['overall_score' => 8, 'source' => 'admin_curated', 'computed_at' => now()]);
        $score->factors()->create(['factor_key' => 'noise', 'score' => 10, 'data_source' => 'admin']);

        [$listing] = $this->publishedListing(neighborhood: $quietNeighborhood);

        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum')->putJson('/api/v1/account/match-preferences', [
            'lifestyle_tags' => ['quiet'],
        ])->assertSuccessful();

        $results = $this->actingAs($user, 'sanctum')->getJson('/api/v1/account/match-results')->json('data');
        $result = collect($results)->firstWhere('listing.id', $listing->id);

        $this->assertEquals(100, $result['score']);
    }

    public function test_saving_new_preferences_recomputes_and_replaces_old_matches(): void
    {
        [$listing] = $this->publishedListing(['bedrooms' => 4]);
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')->putJson('/api/v1/account/match-preferences', [
            'min_bedrooms' => 4,
        ])->assertSuccessful();
        $first = $this->actingAs($user, 'sanctum')->getJson('/api/v1/account/match-results')->json('data');
        $this->assertNotEmpty($first);

        $this->actingAs($user, 'sanctum')->putJson('/api/v1/account/match-preferences', [
            'min_bedrooms' => 10,
        ])->assertOk();
        $second = $this->actingAs($user, 'sanctum')->getJson('/api/v1/account/match-results')->json('data');

        $this->assertEmpty($second, 'raising the requirement well above what exists should drop the match to 0 and be excluded');
        $this->assertDatabaseCount('match_results', 0);
    }

    public function test_saving_preferences_with_false_booleans_persists_as_false_not_null(): void
    {
        $user = User::factory()->create();

        // Mirrors the real frontend payload shape: explicit JSON `false`
        // (not omitted) for every checkbox, which is what a submitted HTML
        // form always sends once every field has a controlled default.
        $response = $this->actingAs($user, 'sanctum')->putJson('/api/v1/account/match-preferences', [
            'purpose' => 'rent',
            'requires_school_nearby' => false,
            'requires_parking' => false,
            'investment_purpose' => false,
        ]);

        $response->assertSuccessful()
            ->assertJsonPath('data.requires_school_nearby', false)
            ->assertJsonPath('data.requires_parking', false)
            ->assertJsonPath('data.investment_purpose', false);

        $this->assertDatabaseHas('match_preferences', [
            'user_id' => $user->id,
            'requires_school_nearby' => false,
            'requires_parking' => false,
            'investment_purpose' => false,
        ]);
    }

    public function test_rejects_an_invalid_lifestyle_tag(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')->putJson('/api/v1/account/match-preferences', [
            'lifestyle_tags' => ['not_a_real_tag'],
        ])->assertUnprocessable();
    }
}
