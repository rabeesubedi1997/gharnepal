<?php

namespace Tests\Feature\Seo;

use App\Models\Municipality;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\Role;
use App\Models\User;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SeoPageManagementTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    private function admin(): User
    {
        $admin = User::factory()->create();
        $admin->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']));

        return $admin;
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
            'price' => 25000,
            'price_period' => 'monthly',
            'title' => 'Seo Test Apartment '.uniqid(),
            'slug' => 'seo-test-apartment-'.uniqid(),
            'status' => PropertyListing::STATUS_PUBLISHED,
            'published_at' => now(),
            'created_by' => $owner->id,
        ]);
    }

    public function test_the_public_static_page_endpoint_returns_auto_generated_defaults(): void
    {
        $response = $this->getJson('/api/v1/seo/pages/home');

        $response->assertOk()
            ->assertJsonPath('data.page_key', 'home')
            ->assertJsonPath('data.has_override', false)
            ->assertJsonPath('data.robots.index', true);

        $this->assertStringContainsString('Ghar Nepal', $response->json('data.title'));
    }

    public function test_an_unknown_static_page_key_is_a_404(): void
    {
        $this->getJson('/api/v1/seo/pages/not-a-real-page')->assertNotFound();
    }

    public function test_listing_detail_carries_auto_generated_seo_by_default(): void
    {
        $listing = $this->publishedListing();

        $response = $this->getJson("/api/v1/listings/{$listing->slug}");

        $response->assertOk()->assertJsonPath('data.seo.has_override', false);
        $this->assertStringContainsString($listing->title, $response->json('data.seo.title'));
        $this->assertSame('RealEstateListing', $response->json('data.seo.structured_data.@type'));
    }

    public function test_admin_index_lists_static_and_listing_pages(): void
    {
        $listing = $this->publishedListing();
        $admin = $this->admin();

        $response = $this->actingAs($admin, 'sanctum')->getJson('/api/v1/admin/seo/pages');

        $response->assertOk();
        $keys = collect($response->json('data'))->pluck('page_key');
        $this->assertTrue($keys->contains('home'));
        $this->assertTrue($keys->contains("listing:{$listing->slug}"));
    }

    public function test_admin_can_publish_an_override_and_it_appears_on_the_public_endpoint(): void
    {
        $admin = $this->admin();

        $this->actingAs($admin, 'sanctum')->putJson('/api/v1/admin/seo/pages/home', [
            'meta_title' => 'Custom Homepage Title',
            'meta_description' => 'Custom homepage description for SEO.',
            'status' => 'published',
        ])->assertOk()->assertJsonPath('data.effective.title', 'Custom Homepage Title');

        $this->getJson('/api/v1/seo/pages/home')
            ->assertJsonPath('data.title', 'Custom Homepage Title')
            ->assertJsonPath('data.has_override', true);
    }

    public function test_a_draft_override_does_not_change_the_live_public_page(): void
    {
        $admin = $this->admin();

        $this->actingAs($admin, 'sanctum')->putJson('/api/v1/admin/seo/pages/home', [
            'meta_title' => 'Draft Title Not Live Yet',
            'status' => 'draft',
        ])->assertOk();

        $response = $this->getJson('/api/v1/seo/pages/home');
        $this->assertNotSame('Draft Title Not Live Yet', $response->json('data.title'));
    }

    public function test_a_draft_overrides_robots_flags_do_not_leak_onto_the_live_page(): void
    {
        $admin = $this->admin();

        $this->actingAs($admin, 'sanctum')->putJson('/api/v1/admin/seo/pages/home', [
            'status' => 'draft',
            'robots_index' => false,
            'robots_follow' => false,
        ])->assertOk();

        $this->getJson('/api/v1/seo/pages/home')
            ->assertJsonPath('data.robots.index', true)
            ->assertJsonPath('data.robots.follow', true);
    }

    public function test_admin_can_reset_an_override_back_to_defaults(): void
    {
        $admin = $this->admin();
        $this->actingAs($admin, 'sanctum')->putJson('/api/v1/admin/seo/pages/home', [
            'meta_title' => 'Temporary',
            'status' => 'published',
        ])->assertOk();

        $this->actingAs($admin, 'sanctum')->deleteJson('/api/v1/admin/seo/pages/home')->assertNoContent();

        $response = $this->getJson('/api/v1/seo/pages/home');
        $this->assertNotSame('Temporary', $response->json('data.title'));
        $this->assertFalse($response->json('data.has_override'));
    }

    public function test_a_non_admin_cannot_manage_seo_pages(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')->getJson('/api/v1/admin/seo/pages')->assertForbidden();
        $this->actingAs($user, 'sanctum')->putJson('/api/v1/admin/seo/pages/home', ['status' => 'published'])->assertForbidden();
    }

    public function test_updating_seo_for_an_unknown_page_key_is_a_404(): void
    {
        $admin = $this->admin();

        $this->actingAs($admin, 'sanctum')->putJson('/api/v1/admin/seo/pages/listing:does-not-exist', [
            'status' => 'published',
        ])->assertNotFound();
    }
}
