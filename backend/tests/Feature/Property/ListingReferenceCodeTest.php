<?php

namespace Tests\Feature\Property;

use App\Models\Municipality;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\User;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ListingReferenceCodeTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    private function publishedListing(): PropertyListing
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

        return $property->listings()->create([
            'purpose' => 'rent',
            'price' => 20000,
            'price_period' => 'monthly',
            'title' => 'Reference code test listing '.uniqid(),
            'slug' => 'reference-code-test-listing-'.uniqid(),
            'status' => PropertyListing::STATUS_PUBLISHED,
            'published_at' => now(),
            'created_by' => $owner->id,
        ]);
    }

    public function test_the_reference_code_is_a_zero_padded_id_with_a_gn_prefix(): void
    {
        $listing = $this->publishedListing();
        $expected = 'GN-'.str_pad((string) $listing->id, 5, '0', STR_PAD_LEFT);

        $this->assertSame($expected, $listing->referenceCode());
    }

    public function test_the_reference_code_appears_on_the_search_and_detail_endpoints(): void
    {
        $listing = $this->publishedListing();
        $expected = $listing->referenceCode();

        $this->getJson('/api/v1/listings')->assertJsonPath('data.0.reference_code', $expected);
        $this->getJson("/api/v1/listings/{$listing->slug}")->assertJsonPath('data.reference_code', $expected);
    }
}
