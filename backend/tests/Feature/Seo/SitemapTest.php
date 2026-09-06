<?php

namespace Tests\Feature\Seo;

use App\Models\Municipality;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\User;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class SitemapTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
        Cache::flush();
    }

    private function listing(string $status): PropertyListing
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
            'price' => 15000,
            'price_period' => 'monthly',
            'title' => 'Sitemap Test Listing '.uniqid(),
            'slug' => 'sitemap-test-listing-'.uniqid(),
            'status' => $status,
            'published_at' => $status === PropertyListing::STATUS_PUBLISHED ? now() : null,
            'created_by' => $owner->id,
        ]);
    }

    public function test_sitemap_lists_static_pages_and_published_listings_only(): void
    {
        $published = $this->listing(PropertyListing::STATUS_PUBLISHED);
        $draft = $this->listing(PropertyListing::STATUS_DRAFT);

        $response = $this->get('/sitemap.xml');

        $response->assertOk();
        $this->assertStringContainsString('application/xml', $response->headers->get('Content-Type'));

        $body = $response->getContent();
        $this->assertStringContainsString('<loc>'.config('app.frontend_url').'/</loc>', $body);
        $this->assertStringContainsString("/listings/{$published->slug}", $body);
        $this->assertStringNotContainsString("/listings/{$draft->slug}", $body);
    }

    public function test_robots_txt_disallows_private_areas_and_points_to_the_sitemap(): void
    {
        $response = $this->get('/robots.txt');

        $response->assertOk();
        $this->assertStringContainsString('text/plain', $response->headers->get('Content-Type'));

        $body = $response->getContent();
        $this->assertStringContainsString('Disallow: /admin', $body);
        $this->assertStringContainsString('Sitemap: '.config('app.frontend_url').'/sitemap.xml', $body);
    }
}
