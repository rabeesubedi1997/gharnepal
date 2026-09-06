<?php

namespace Tests\Feature\Calculators;

use App\Models\Municipality;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\User;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PriceIntelligenceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    private function listingInWard1(User $owner, float $price, string $title, string $status = PropertyListing::STATUS_PUBLISHED): PropertyListing
    {
        $municipality = Municipality::where('code', 'M-KTM')->firstOrFail();
        $ward = Ward::where('municipality_id', $municipality->id)->where('ward_number', 1)->firstOrFail();

        $property = Property::create([
            'owner_user_id' => $owner->id,
            'created_by' => $owner->id,
            'property_type' => 'apartment',
            'total_area_sqm' => 100,
            'bedrooms' => 2,
            'bathrooms' => 1,
        ]);
        $property->address()->create([
            'province_id' => $municipality->district->province_id,
            'district_id' => $municipality->district_id,
            'municipality_id' => $municipality->id,
            'ward_id' => $ward->id,
        ]);
        $property->managers()->attach($owner->id, ['relation' => 'owner']);

        return PropertyListing::create([
            'property_id' => $property->id,
            'purpose' => 'rent',
            'price' => $price,
            'price_period' => 'monthly',
            'title' => $title,
            'slug' => str()->slug($title) . '-' . uniqid(),
            'status' => $status,
            'published_at' => $status === PropertyListing::STATUS_PUBLISHED ? now() : null,
            'created_by' => $owner->id,
        ]);
    }

    public function test_changing_a_listings_price_records_price_history(): void
    {
        $owner = User::factory()->create();
        $listing = $this->listingInWard1($owner, 20000, 'Test listing', PropertyListing::STATUS_DRAFT);

        $this->actingAs($owner, 'sanctum')->putJson("/api/v1/owner/listings/{$listing->id}", [
            'price' => 22000,
        ])->assertOk();

        $this->assertDatabaseHas('price_history', ['property_listing_id' => $listing->id, 'price' => 22000, 'changed_by' => $owner->id]);
        $this->assertDatabaseMissing('price_history', ['property_listing_id' => $listing->id, 'price' => 20000]);
    }

    public function test_updating_without_changing_price_does_not_add_a_history_row(): void
    {
        $owner = User::factory()->create();
        $listing = $this->listingInWard1($owner, 20000, 'Test listing', PropertyListing::STATUS_DRAFT);

        $this->actingAs($owner, 'sanctum')->putJson("/api/v1/owner/listings/{$listing->id}", [
            'title' => 'Updated title only',
        ])->assertOk();

        $this->assertDatabaseCount('price_history', 0);
    }

    public function test_the_public_listing_shows_price_history_and_similar_listings(): void
    {
        $owner = User::factory()->create();
        $listing = $this->listingInWard1($owner, 20000, 'Main listing for sale');
        $this->listingInWard1(User::factory()->create(), 21000, 'Very similar nearby listing');

        $this->actingAs($owner, 'sanctum')->putJson("/api/v1/owner/listings/{$listing->id}", ['price' => 23000])->assertOk();

        $response = $this->getJson("/api/v1/listings/{$listing->slug}");

        $response->assertOk();
        $this->assertGreaterThanOrEqual(1, count($response->json('data.price_history')));
        $this->assertCount(1, $response->json('data.similar_listings'));
        $this->assertEquals('Very similar nearby listing', $response->json('data.similar_listings.0.title'));
    }
}
