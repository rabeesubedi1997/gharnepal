<?php

namespace Tests\Feature\Listings;

use App\Models\Municipality;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\User;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ListingContactTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    private function listingFor(User $owner): PropertyListing
    {
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

        return $property->listings()->create([
            'purpose' => 'rent',
            'price' => 20000,
            'price_period' => 'monthly',
            'title' => 'Contact test listing ' . uniqid(),
            'slug' => 'contact-test-listing-' . uniqid(),
            'status' => PropertyListing::STATUS_PUBLISHED,
            'published_at' => now(),
            'created_by' => $owner->id,
        ]);
    }

    public function test_a_phone_verified_owners_whatsapp_link_is_exposed(): void
    {
        $owner = User::factory()->create(['phone' => '+977 9801234567', 'phone_verified_at' => now()]);
        $listing = $this->listingFor($owner);

        $response = $this->getJson("/api/v1/listings/{$listing->slug}");

        $response->assertOk()->assertJsonPath('data.poster.whatsapp_url', 'https://wa.me/9779801234567');
    }

    public function test_an_unverified_phone_is_not_exposed_as_a_whatsapp_link(): void
    {
        $owner = User::factory()->create(['phone' => '+977 9801234567', 'phone_verified_at' => null]);
        $listing = $this->listingFor($owner);

        $response = $this->getJson("/api/v1/listings/{$listing->slug}");

        $response->assertOk()->assertJsonPath('data.poster.whatsapp_url', null);
    }
}
