<?php

namespace Tests\Feature\Admin;

use App\Models\Advertisement;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class AdvertisementManagementTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    private function admin(): User
    {
        $admin = User::factory()->create();
        $admin->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']));

        return $admin;
    }

    public function test_admin_can_create_an_advertisement_targeting_a_placement(): void
    {
        $admin = $this->admin();

        $response = $this->actingAs($admin, 'sanctum')->post('/api/v1/admin/advertisements', [
            'title' => 'List your property with us',
            'link_url' => '/post-property',
            'cta_label' => 'Get started',
            'placement' => 'search_sidebar',
            'image' => UploadedFile::fake()->image('ad.jpg', 600, 600),
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.title', 'List your property with us')
            ->assertJsonPath('data.placement', 'search_sidebar');
        $this->assertDatabaseCount('advertisements', 1);
        Storage::disk('public')->assertExists(Advertisement::first()->image_path);
    }

    public function test_an_invalid_placement_is_rejected(): void
    {
        $admin = $this->admin();

        $this->actingAs($admin, 'sanctum')->post('/api/v1/admin/advertisements', [
            'placement' => 'not_a_real_slot',
            'image' => UploadedFile::fake()->image('ad.jpg'),
        ], ['Accept' => 'application/json'])->assertUnprocessable()->assertJsonValidationErrors('placement');
    }

    public function test_the_public_endpoint_requires_a_placement_and_only_returns_that_slots_active_ads(): void
    {
        Advertisement::create(['image_path' => 'advertisements/a.jpg', 'placement' => 'search_sidebar', 'is_active' => true, 'sort_order' => 0]);
        Advertisement::create(['image_path' => 'advertisements/b.jpg', 'placement' => 'search_sidebar', 'is_active' => false, 'sort_order' => 1]);
        Advertisement::create(['image_path' => 'advertisements/c.jpg', 'placement' => 'home_before_footer', 'is_active' => true, 'sort_order' => 0]);

        $this->getJson('/api/v1/advertisements')->assertUnprocessable();

        $response = $this->getJson('/api/v1/advertisements?placement=search_sidebar');
        $response->assertOk()->assertJsonCount(1, 'data');
        $response->assertJsonPath('data.0.placement', 'search_sidebar');
    }

    public function test_admin_sees_every_advertisement_including_inactive(): void
    {
        $admin = $this->admin();
        Advertisement::create(['image_path' => 'advertisements/a.jpg', 'placement' => 'search_sidebar', 'is_active' => true, 'sort_order' => 0]);
        Advertisement::create(['image_path' => 'advertisements/b.jpg', 'placement' => 'search_sidebar', 'is_active' => false, 'sort_order' => 1]);

        $this->actingAs($admin, 'sanctum')->getJson('/api/v1/admin/advertisements')
            ->assertOk()->assertJsonCount(2, 'data');
    }

    public function test_admin_can_update_an_advertisement_and_replace_its_image(): void
    {
        $admin = $this->admin();
        $ad = Advertisement::create(['image_path' => 'advertisements/old.jpg', 'placement' => 'search_sidebar', 'title' => 'Old', 'is_active' => true, 'sort_order' => 0]);
        Storage::disk('public')->put('advertisements/old.jpg', 'fake');

        $response = $this->actingAs($admin, 'sanctum')->post("/api/v1/admin/advertisements/{$ad->id}", [
            '_method' => 'PUT',
            'title' => 'New',
            'image' => UploadedFile::fake()->image('new.jpg'),
        ]);

        $response->assertOk()->assertJsonPath('data.title', 'New');
        $ad->refresh();
        $this->assertNotSame('advertisements/old.jpg', $ad->image_path);
        Storage::disk('public')->assertMissing('advertisements/old.jpg');
    }

    public function test_admin_can_toggle_an_advertisement_inactive(): void
    {
        $admin = $this->admin();
        $ad = Advertisement::create(['image_path' => 'advertisements/a.jpg', 'placement' => 'search_sidebar', 'is_active' => true, 'sort_order' => 0]);

        $this->actingAs($admin, 'sanctum')->putJson("/api/v1/admin/advertisements/{$ad->id}", [
            'is_active' => false,
        ])->assertOk()->assertJsonPath('data.is_active', false);

        $this->getJson('/api/v1/advertisements?placement=search_sidebar')->assertJsonCount(0, 'data');
    }

    public function test_admin_can_delete_an_advertisement(): void
    {
        $admin = $this->admin();
        $ad = Advertisement::create(['image_path' => 'advertisements/a.jpg', 'placement' => 'search_sidebar', 'is_active' => true, 'sort_order' => 0]);
        Storage::disk('public')->put('advertisements/a.jpg', 'fake');

        $this->actingAs($admin, 'sanctum')->deleteJson("/api/v1/admin/advertisements/{$ad->id}")->assertNoContent();

        $this->assertDatabaseMissing('advertisements', ['id' => $ad->id]);
        Storage::disk('public')->assertMissing('advertisements/a.jpg');
    }

    public function test_a_non_admin_cannot_manage_advertisements(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')->getJson('/api/v1/admin/advertisements')->assertForbidden();
        $this->actingAs($user, 'sanctum')->postJson('/api/v1/admin/advertisements', [])->assertForbidden();
    }

    public function test_creating_an_advertisement_without_an_image_is_rejected(): void
    {
        $admin = $this->admin();

        $this->actingAs($admin, 'sanctum')->postJson('/api/v1/admin/advertisements', [
            'placement' => 'search_sidebar',
        ])->assertUnprocessable();
    }
}
