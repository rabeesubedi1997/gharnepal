<?php

namespace Tests\Feature;

use App\Models\Agency;
use App\Models\Municipality;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\SavedSearch;
use App\Models\User;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * The homepage's trust/transparency strip reads from GET /platform-stats —
 * every number here must be real, not the kind of invented "Rs 120Cr+
 * facilitated" figure a redesign mockup tends to show.
 */
class PlatformStatsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    private function publishedListing(User $owner): PropertyListing
    {
        $municipality = Municipality::where('code', 'M-KTM')->firstOrFail();
        $ward = Ward::where('municipality_id', $municipality->id)->first();

        $property = Property::create([
            'owner_user_id' => $owner->id,
            'created_by' => $owner->id,
            'property_type' => 'apartment',
            'total_area_sqm' => 100,
        ]);
        $property->address()->create([
            'province_id' => $municipality->district->province_id,
            'district_id' => $municipality->district_id,
            'municipality_id' => $municipality->id,
            'ward_id' => $ward->id,
        ]);

        return $property->listings()->create([
            'purpose' => 'rent',
            'price' => 20000,
            'title' => 'Stats test listing ' . uniqid(),
            'slug' => 'stats-test-listing-' . uniqid(),
            'status' => PropertyListing::STATUS_PUBLISHED,
            'published_at' => now(),
            'created_by' => $owner->id,
        ]);
    }

    public function test_it_returns_real_counts(): void
    {
        $verifiedOwner = User::factory()->create(['phone_verified_at' => now()]);
        $unverifiedOwner = User::factory()->create(['phone_verified_at' => null]);

        $this->publishedListing($verifiedOwner);
        $this->publishedListing($unverifiedOwner);

        Agency::create(['name' => 'Verified Co', 'slug' => 'verified-co', 'status' => 'active', 'verified_at' => now()]);
        Agency::create(['name' => 'Pending Co', 'slug' => 'pending-co', 'status' => 'pending']);

        SavedSearch::create(['user_id' => $verifiedOwner->id, 'name' => 'Instant one', 'filters' => [], 'alert_frequency' => 'instant']);
        SavedSearch::create(['user_id' => $verifiedOwner->id, 'name' => 'Daily one', 'filters' => [], 'alert_frequency' => 'daily']);
        SavedSearch::create(['user_id' => $unverifiedOwner->id, 'name' => 'Alerts off', 'filters' => [], 'alert_frequency' => 'off']);

        $response = $this->getJson('/api/v1/platform-stats');

        $response->assertOk()
            ->assertJsonPath('data.published_listings', 2)
            ->assertJsonPath('data.verified_agencies', 1)
            ->assertJsonPath('data.phone_verified_owner_pct', 50)
            ->assertJsonPath('data.cities_covered', 1)
            ->assertJsonPath('data.active_alert_subscriptions', 2);
    }

    public function test_land_price_per_aana_is_a_real_median_not_an_average(): void
    {
        $owner = User::factory()->create();
        $municipality = Municipality::where('code', 'M-KTM')->firstOrFail();
        $ward = Ward::where('municipality_id', $municipality->id)->first();

        // 3 land listings, ~100 sqm (~3.15 aana) each, prices chosen so the
        // median (middle value) differs from the mean — proves this isn't
        // silently just an average.
        foreach ([3_000_000, 3_200_000, 50_000_000] as $price) {
            $property = Property::create([
                'owner_user_id' => $owner->id,
                'created_by' => $owner->id,
                'property_type' => 'land',
                'total_area_sqm' => 100,
            ]);
            $property->address()->create([
                'province_id' => $municipality->district->province_id,
                'district_id' => $municipality->district_id,
                'municipality_id' => $municipality->id,
                'ward_id' => $ward->id,
            ]);
            $property->listings()->create([
                'purpose' => 'sale',
                'price' => $price,
                'title' => 'Land listing ' . uniqid(),
                'slug' => 'land-listing-' . uniqid(),
                'status' => PropertyListing::STATUS_PUBLISHED,
                'published_at' => now(),
                'created_by' => $owner->id,
            ]);
        }

        $response = $this->getJson('/api/v1/platform-stats');

        $response->assertOk();
        $row = collect($response->json('data.land_price_per_aana_by_city'))->firstWhere('municipality', $municipality->name);
        $this->assertNotNull($row);
        $this->assertSame(3, $row['listing_count']);
        // Median price/aana should track the middle listing (3.2M), not the
        // mean (~18.7M) that the 50M outlier would otherwise pull toward.
        $expectedMedian = (int) round(3_200_000 / \App\Domain\Calculators\Services\AreaUnitConverter::fromSqm(100, 'aana'));
        $this->assertEqualsWithDelta($expectedMedian, $row['median_price_per_aana'], 5);
    }

    public function test_it_never_exposes_payment_amounts(): void
    {
        // Structural guard against a future edit re-introducing a fabricated
        // "value transacted" figure — the sandbox gateway moves no real
        // money, so any monetary total here would misrepresent test data.
        $response = $this->getJson('/api/v1/platform-stats');

        $response->assertOk();
        $keys = array_keys($response->json('data'));
        foreach ($keys as $key) {
            $this->assertStringNotContainsStringIgnoringCase('amount', $key);
            $this->assertStringNotContainsStringIgnoringCase('revenue', $key);
            $this->assertStringNotContainsStringIgnoringCase('transaction', $key);
        }
    }
}
