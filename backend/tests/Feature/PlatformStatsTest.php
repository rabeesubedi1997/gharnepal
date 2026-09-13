<?php

namespace Tests\Feature;

use App\Models\Agency;
use App\Models\Municipality;
use App\Models\Property;
use App\Models\PropertyListing;
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

        $response = $this->getJson('/api/v1/platform-stats');

        $response->assertOk()
            ->assertJsonPath('data.published_listings', 2)
            ->assertJsonPath('data.verified_agencies', 1)
            ->assertJsonPath('data.phone_verified_owner_pct', 50)
            ->assertJsonPath('data.cities_covered', 1);
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
