<?php

namespace Tests\Feature\Property;

use App\Models\Municipality;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\User;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ListingVideoTourTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, NepalLocationSeeder::class]);
    }

    private function createProperty(User $owner): Property
    {
        $municipality = Municipality::where('code', 'M-KTM')->firstOrFail();
        $ward = Ward::where('municipality_id', $municipality->id)->first();

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

        return $property;
    }

    public function test_owner_can_attach_a_youtube_link_when_creating_a_listing(): void
    {
        $owner = User::factory()->create();
        $property = $this->createProperty($owner);

        $response = $this->actingAs($owner, 'sanctum')->postJson("/api/v1/properties/{$property->id}/listings", [
            'purpose' => 'sale',
            'price' => 5000000,
            'title' => 'House with a video tour',
            'video_url' => 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.video_url', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ')
            ->assertJsonPath('data.video_tour.embed_url', 'https://www.youtube.com/embed/dQw4w9WgXcQ');
    }

    public function test_a_vimeo_link_also_works(): void
    {
        $owner = User::factory()->create();
        $property = $this->createProperty($owner);

        $response = $this->actingAs($owner, 'sanctum')->postJson("/api/v1/properties/{$property->id}/listings", [
            'purpose' => 'sale',
            'price' => 5000000,
            'title' => 'House with a Vimeo tour',
            'video_url' => 'https://vimeo.com/76979871',
        ]);

        $response->assertCreated()->assertJsonPath('data.video_tour.embed_url', 'https://player.vimeo.com/video/76979871');
    }

    public function test_an_unrecognized_video_host_is_rejected(): void
    {
        $owner = User::factory()->create();
        $property = $this->createProperty($owner);

        $this->actingAs($owner, 'sanctum')->postJson("/api/v1/properties/{$property->id}/listings", [
            'purpose' => 'sale',
            'price' => 5000000,
            'title' => 'Suspicious embed attempt',
            'video_url' => 'https://evil.example.com/embed?src=phish',
        ])->assertUnprocessable()->assertJsonValidationErrors(['video_url']);
    }

    public function test_owner_can_update_the_video_link_on_an_existing_listing(): void
    {
        $owner = User::factory()->create();
        $property = $this->createProperty($owner);
        $listing = PropertyListing::create([
            'property_id' => $property->id,
            'purpose' => 'sale',
            'price' => 1000000,
            'title' => 'Plain listing',
            'slug' => 'plain-listing-video-test',
            'status' => PropertyListing::STATUS_DRAFT,
            'created_by' => $owner->id,
        ]);

        $this->actingAs($owner, 'sanctum')
            ->putJson("/api/v1/owner/listings/{$listing->id}", ['video_url' => 'https://youtu.be/dQw4w9WgXcQ'])
            ->assertOk()
            ->assertJsonPath('data.video_tour.embed_url', 'https://www.youtube.com/embed/dQw4w9WgXcQ');

        $this->assertSame('https://youtu.be/dQw4w9WgXcQ', $listing->fresh()->video_url);
    }

    public function test_the_public_listing_endpoint_exposes_the_video_tour(): void
    {
        $owner = User::factory()->create();
        $property = $this->createProperty($owner);
        $listing = PropertyListing::create([
            'property_id' => $property->id,
            'purpose' => 'sale',
            'price' => 1000000,
            'title' => 'Published listing with a tour',
            'slug' => 'published-listing-with-a-tour',
            'status' => PropertyListing::STATUS_PUBLISHED,
            'published_at' => now(),
            'video_url' => 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            'created_by' => $owner->id,
        ]);

        $this->getJson("/api/v1/listings/{$listing->slug}")
            ->assertOk()
            ->assertJsonPath('data.video_tour.embed_url', 'https://www.youtube.com/embed/dQw4w9WgXcQ');
    }
}
