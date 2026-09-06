<?php

namespace Tests\Feature\Admin;

use App\Models\Banner;
use App\Models\Role;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class BannerManagementTest extends TestCase
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

    public function test_admin_can_create_a_banner_with_an_image(): void
    {
        $admin = $this->admin();

        $response = $this->actingAs($admin, 'sanctum')->post('/api/v1/admin/banners', [
            'title' => 'Verified Land Deals in Kathmandu',
            'subtitle' => 'Browse admin-reviewed land plots across the valley',
            'link_url' => '/search?property_type=land',
            'cta_label' => 'Browse land',
            'image' => UploadedFile::fake()->image('banner.jpg', 1600, 600),
        ]);

        $response->assertCreated()->assertJsonPath('data.title', 'Verified Land Deals in Kathmandu');
        $this->assertDatabaseCount('banners', 1);
        Storage::disk('public')->assertExists(Banner::first()->image_path);
    }

    public function test_only_active_banners_are_public(): void
    {
        Banner::create(['image_path' => 'banners/active.jpg', 'is_active' => true, 'sort_order' => 0]);
        Banner::create(['image_path' => 'banners/inactive.jpg', 'is_active' => false, 'sort_order' => 1]);

        $response = $this->getJson('/api/v1/banners');

        $response->assertOk()->assertJsonCount(1, 'data');
    }

    public function test_admin_sees_every_banner_including_inactive(): void
    {
        $admin = $this->admin();
        Banner::create(['image_path' => 'banners/a.jpg', 'is_active' => true, 'sort_order' => 0]);
        Banner::create(['image_path' => 'banners/b.jpg', 'is_active' => false, 'sort_order' => 1]);

        $this->actingAs($admin, 'sanctum')->getJson('/api/v1/admin/banners')
            ->assertOk()->assertJsonCount(2, 'data');
    }

    public function test_admin_can_update_a_banner_and_replace_its_image(): void
    {
        $admin = $this->admin();
        $banner = Banner::create(['image_path' => 'banners/old.jpg', 'title' => 'Old title', 'is_active' => true, 'sort_order' => 0]);
        Storage::disk('public')->put('banners/old.jpg', 'fake');

        $response = $this->actingAs($admin, 'sanctum')->post("/api/v1/admin/banners/{$banner->id}", [
            '_method' => 'PUT',
            'title' => 'New title',
            'image' => UploadedFile::fake()->image('new.jpg'),
        ]);

        $response->assertOk()->assertJsonPath('data.title', 'New title');
        $banner->refresh();
        $this->assertNotSame('banners/old.jpg', $banner->image_path);
        Storage::disk('public')->assertMissing('banners/old.jpg');
    }

    public function test_admin_can_toggle_a_banner_inactive(): void
    {
        $admin = $this->admin();
        $banner = Banner::create(['image_path' => 'banners/a.jpg', 'is_active' => true, 'sort_order' => 0]);

        $this->actingAs($admin, 'sanctum')->putJson("/api/v1/admin/banners/{$banner->id}", [
            'is_active' => false,
        ])->assertOk()->assertJsonPath('data.is_active', false);

        $this->getJson('/api/v1/banners')->assertJsonCount(0, 'data');
    }

    public function test_admin_can_delete_a_banner(): void
    {
        $admin = $this->admin();
        $banner = Banner::create(['image_path' => 'banners/a.jpg', 'is_active' => true, 'sort_order' => 0]);
        Storage::disk('public')->put('banners/a.jpg', 'fake');

        $this->actingAs($admin, 'sanctum')->deleteJson("/api/v1/admin/banners/{$banner->id}")->assertNoContent();

        $this->assertDatabaseMissing('banners', ['id' => $banner->id]);
        Storage::disk('public')->assertMissing('banners/a.jpg');
    }

    public function test_a_non_admin_cannot_manage_banners(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')->getJson('/api/v1/admin/banners')->assertForbidden();
        $this->actingAs($user, 'sanctum')->postJson('/api/v1/admin/banners', [])->assertForbidden();
    }

    public function test_creating_a_banner_without_an_image_is_rejected(): void
    {
        $admin = $this->admin();

        $this->actingAs($admin, 'sanctum')->postJson('/api/v1/admin/banners', [
            'title' => 'No image',
        ])->assertUnprocessable();
    }
}
