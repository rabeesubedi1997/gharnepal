<?php

namespace Tests\Feature\Agencies;

use App\Models\Agency;
use App\Models\Municipality;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\User;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AgencyDirectoryTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    private function publishedListingFor(User $agent): PropertyListing
    {
        $municipality = Municipality::where('code', 'M-KTM')->firstOrFail();
        $ward = Ward::where('municipality_id', $municipality->id)->where('ward_number', 1)->firstOrFail();

        $property = Property::create([
            'owner_user_id' => $agent->id,
            'created_by' => $agent->id,
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
        $property->managers()->attach($agent->id, ['relation' => 'listing_agent']);

        return $property->listings()->create([
            'purpose' => 'rent',
            'price' => 20000,
            'price_period' => 'monthly',
            'title' => 'Agency test listing ' . uniqid(),
            'slug' => 'agency-test-listing-' . uniqid(),
            'status' => PropertyListing::STATUS_PUBLISHED,
            'published_at' => now(),
            'created_by' => $agent->id,
        ]);
    }

    public function test_only_verified_agencies_appear_in_the_public_directory(): void
    {
        $verified = Agency::create(['name' => 'Verified Agency', 'slug' => 'verified-agency', 'status' => 'active', 'verified_at' => now()]);
        Agency::create(['name' => 'Pending Agency', 'slug' => 'pending-agency', 'status' => 'pending', 'verified_at' => null]);

        $response = $this->getJson('/api/v1/agencies');

        $response->assertOk();
        $names = collect($response->json('data'))->pluck('name');
        $this->assertTrue($names->contains('Verified Agency'));
        $this->assertFalse($names->contains('Pending Agency'));
    }

    public function test_agency_profile_shows_members_and_active_listings(): void
    {
        $agency = Agency::create(['name' => 'Himalayan Test Realty', 'slug' => 'himalayan-test-realty', 'status' => 'active', 'verified_at' => now()]);
        $agent = User::factory()->create(['name' => 'Test Agent']);
        $agency->members()->attach($agent->id, ['role_in_agency' => 'agent']);

        $listing = $this->publishedListingFor($agent);

        $response = $this->getJson('/api/v1/agencies/himalayan-test-realty');

        $response->assertOk()
            ->assertJsonPath('data.name', 'Himalayan Test Realty')
            ->assertJsonPath('data.is_verified', true)
            ->assertJsonPath('data.member_count', 1)
            ->assertJsonPath('data.members.0.name', 'Test Agent');

        $listingIds = collect($response->json('data.active_listings'))->pluck('id');
        $this->assertTrue($listingIds->contains($listing->id));
    }

    public function test_an_unverified_agency_profile_is_not_reachable_by_slug(): void
    {
        Agency::create(['name' => 'Unverified Agency', 'slug' => 'unverified-agency', 'status' => 'pending', 'verified_at' => null]);

        $this->getJson('/api/v1/agencies/unverified-agency')->assertNotFound();
    }

    public function test_a_non_member_listing_is_not_attributed_to_an_unrelated_agency(): void
    {
        $agency = Agency::create(['name' => 'Empty Agency', 'slug' => 'empty-agency', 'status' => 'active', 'verified_at' => now()]);
        $outsider = User::factory()->create();
        $this->publishedListingFor($outsider); // not a member of $agency

        $response = $this->getJson('/api/v1/agencies/empty-agency');

        $response->assertOk()->assertJsonCount(0, 'data.active_listings');
    }
}
