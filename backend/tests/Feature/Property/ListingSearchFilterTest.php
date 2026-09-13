<?php

namespace Tests\Feature\Property;

use App\Models\Amenity;
use App\Models\Municipality;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\User;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Both amenities and parking_type were collected in the post-property wizard
 * and shown on listing detail, but a buyer could never actually filter
 * search by either — this covers the fix.
 */
class ListingSearchFilterTest extends TestCase
{
    use RefreshDatabase;

    private function publishedListing(array $propertyAttrs = [], array $listingAttrs = [], array $addressAttrs = []): PropertyListing
    {
        $owner = User::factory()->create();
        $municipality = Municipality::where('code', 'M-KTM')->firstOrFail();
        $ward = Ward::where('municipality_id', $municipality->id)->where('ward_number', 1)->firstOrFail();

        $property = Property::create([
            'owner_user_id' => $owner->id,
            'created_by' => $owner->id,
            'property_type' => 'apartment',
            'bedrooms' => 2,
            'bathrooms' => 1,
            'parking_spaces' => 1,
            'parking_type' => 'car',
            ...$propertyAttrs,
        ]);
        $property->address()->create([
            'province_id' => $municipality->district->province_id,
            'district_id' => $municipality->district_id,
            'municipality_id' => $municipality->id,
            'ward_id' => $ward->id,
            ...$addressAttrs,
        ]);

        return $property->listings()->create([
            'purpose' => 'rent',
            'price' => 25000,
            'title' => 'A searchable test listing '.uniqid(),
            'slug' => 'searchable-test-listing-'.uniqid(),
            'status' => PropertyListing::STATUS_PUBLISHED,
            'published_at' => now(),
            'created_by' => $owner->id,
            ...$listingAttrs,
        ]);
    }

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    public function test_search_can_filter_by_parking_type(): void
    {
        $car = $this->publishedListing(['parking_type' => 'car']);
        $bike = $this->publishedListing(['parking_type' => 'bike']);

        $response = $this->getJson('/api/v1/listings?parking_type=bike')->assertOk();
        $ids = collect($response->json('data'))->pluck('id');

        $this->assertTrue($ids->contains($bike->id));
        $this->assertFalse($ids->contains($car->id));
    }

    public function test_search_can_filter_by_amenities_requiring_all_selected(): void
    {
        $wifi = Amenity::create(['key' => 'wifi', 'name' => 'WiFi']);
        $lift = Amenity::create(['key' => 'lift', 'name' => 'Lift']);

        $both = $this->publishedListing();
        $both->amenities()->attach([$wifi->id, $lift->id]);

        $wifiOnly = $this->publishedListing();
        $wifiOnly->amenities()->attach([$wifi->id]);

        $response = $this->getJson('/api/v1/listings?amenity_ids[]='.$wifi->id.'&amenity_ids[]='.$lift->id)->assertOk();
        $ids = collect($response->json('data'))->pluck('id');

        $this->assertTrue($ids->contains($both->id));
        $this->assertFalse($ids->contains($wifiOnly->id));
    }

    public function test_search_can_filter_by_a_hand_drawn_map_polygon(): void
    {
        // A small square roughly over central Kathmandu.
        $polygon = '27.70,85.30|27.70,85.35|27.75,85.35|27.75,85.30';

        $inside = $this->publishedListing(addressAttrs: ['lat' => 27.72, 'lng' => 85.32]);
        $outside = $this->publishedListing(addressAttrs: ['lat' => 28.20, 'lng' => 83.99]); // Pokhara — well outside
        $noCoordinates = $this->publishedListing();

        $response = $this->getJson('/api/v1/listings?polygon='.urlencode($polygon))->assertOk();
        $ids = collect($response->json('data'))->pluck('id');

        $this->assertTrue($ids->contains($inside->id));
        $this->assertFalse($ids->contains($outside->id));
        $this->assertFalse($ids->contains($noCoordinates->id));
    }

    public function test_a_malformed_polygon_is_rejected(): void
    {
        $this->getJson('/api/v1/listings?polygon=not-a-polygon')->assertUnprocessable();
        $this->getJson('/api/v1/listings?polygon='.urlencode('27.70,85.30|27.75,85.35')) // only 2 points
            ->assertUnprocessable();
    }
}
