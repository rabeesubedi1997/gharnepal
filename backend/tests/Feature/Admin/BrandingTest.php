<?php

namespace Tests\Feature\Admin;

use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class BrandingTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        $user = User::factory()->create();
        $user->roles()->attach(Role::create(['key' => Role::ADMIN, 'name' => 'Admin']));

        return $user;
    }

    private function superAdmin(): User
    {
        $user = User::factory()->create();
        $user->roles()->attach(Role::create(['key' => Role::SUPER_ADMIN, 'name' => 'Super Admin']));

        return $user;
    }

    public function test_the_public_endpoint_returns_defaults_before_any_admin_touches_it(): void
    {
        $this->getJson('/api/v1/branding')
            ->assertOk()
            ->assertJsonPath('data.site_name', 'Ghar Nepal')
            ->assertJsonPath('data.favicon_url', null)
            ->assertJsonPath('data.app_icon_url', null);
    }

    public function test_a_super_admin_can_change_the_site_name_and_upload_a_favicon(): void
    {
        Storage::fake('public');

        $this->actingAs($this->superAdmin(), 'sanctum')
            ->post('/api/v1/admin/branding', [
                'site_name' => 'Himalayan Homes',
                'favicon' => UploadedFile::fake()->image('favicon.png', 64, 64),
            ])
            ->assertOk()
            ->assertJsonPath('data.site_name', 'Himalayan Homes');

        $this->getJson('/api/v1/branding')
            ->assertJsonPath('data.site_name', 'Himalayan Homes')
            ->assertJsonPath('data.favicon_url', fn ($url) => str_contains($url, '/storage/branding/'));
    }

    public function test_a_regular_admin_can_also_change_branding(): void
    {
        $this->actingAs($this->admin(), 'sanctum')
            ->post('/api/v1/admin/branding', ['site_name' => 'Not Just Super Admins'])
            ->assertOk()
            ->assertJsonPath('data.site_name', 'Not Just Super Admins');
    }

    public function test_a_regular_admin_can_still_view_current_branding(): void
    {
        $this->actingAs($this->admin(), 'sanctum')
            ->getJson('/api/v1/admin/branding')
            ->assertOk()
            ->assertJsonPath('data.site_name', 'Ghar Nepal');
    }

    public function test_uploading_a_new_favicon_deletes_the_old_one(): void
    {
        Storage::fake('public');
        $superAdmin = $this->superAdmin();

        $this->actingAs($superAdmin, 'sanctum')->post('/api/v1/admin/branding', [
            'favicon' => UploadedFile::fake()->image('first.png', 64, 64),
        ]);
        $firstPath = \App\Models\PlatformBranding::current()->favicon_path;
        Storage::disk('public')->assertExists($firstPath);

        $this->actingAs($superAdmin, 'sanctum')->post('/api/v1/admin/branding', [
            'favicon' => UploadedFile::fake()->image('second.png', 64, 64),
        ]);

        Storage::disk('public')->assertMissing($firstPath);
    }

    public function test_a_guest_cannot_view_or_change_admin_branding(): void
    {
        $this->getJson('/api/v1/admin/branding')->assertUnauthorized();
        $this->postJson('/api/v1/admin/branding', ['site_name' => 'x'])->assertUnauthorized();
    }
}
