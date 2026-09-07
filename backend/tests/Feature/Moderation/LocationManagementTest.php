<?php

namespace Tests\Feature\Moderation;

use App\Models\Municipality;
use App\Models\Province;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class LocationManagementTest extends TestCase
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

    public function test_an_admin_can_create_a_province_and_district(): void
    {
        $admin = $this->admin();

        $province = $this->actingAs($admin, 'sanctum')->postJson('/api/v1/admin/locations/provinces', [
            'name' => 'Lumbini Province', 'code' => 'P5',
        ]);
        $province->assertCreated()->assertJsonPath('data.name', 'Lumbini Province');

        $district = $this->actingAs($admin, 'sanctum')->postJson('/api/v1/admin/locations/districts', [
            'province_id' => $province->json('data.id'), 'name' => 'Rupandehi', 'code' => 'D-RPD',
        ]);
        $district->assertCreated()->assertJsonPath('data.name', 'Rupandehi');
    }

    public function test_creating_a_municipality_auto_provisions_its_wards(): void
    {
        $admin = $this->admin();
        $province = Province::create(['name' => 'Lumbini Province', 'code' => 'P5']);
        $district = $province->districts()->create(['name' => 'Rupandehi', 'code' => 'D-RPD']);

        $response = $this->actingAs($admin, 'sanctum')->postJson('/api/v1/admin/locations/municipalities', [
            'district_id' => $district->id,
            'name' => 'Butwal Sub-Metropolitan City',
            'type' => 'sub_metropolitan',
            'code' => 'M-BTL',
            'ward_count' => 19,
        ]);

        $response->assertCreated();
        $this->assertDatabaseCount('wards', 19);
    }

    public function test_a_municipality_can_be_created_with_a_photo(): void
    {
        $admin = $this->admin();
        $province = Province::create(['name' => 'Lumbini Province', 'code' => 'P5']);
        $district = $province->districts()->create(['name' => 'Rupandehi', 'code' => 'D-RPD']);

        $response = $this->actingAs($admin, 'sanctum')->post('/api/v1/admin/locations/municipalities', [
            'district_id' => $district->id,
            'name' => 'Butwal Sub-Metropolitan City',
            'type' => 'sub_metropolitan',
            'code' => 'M-BTL',
            'ward_count' => 5,
            'image' => UploadedFile::fake()->image('butwal.jpg', 800, 600),
        ]);

        $response->assertCreated();
        $this->assertNotNull($response->json('data.image_url'));
        Storage::disk('public')->assertExists(Municipality::first()->image_path);
    }

    public function test_a_photo_can_be_added_to_an_existing_municipality(): void
    {
        $admin = $this->admin();
        $province = Province::create(['name' => 'Lumbini Province', 'code' => 'P5']);
        $district = $province->districts()->create(['name' => 'Rupandehi', 'code' => 'D-RPD']);
        $municipality = Municipality::create([
            'district_id' => $district->id,
            'name' => 'Butwal Sub-Metropolitan City',
            'type' => 'sub_metropolitan',
            'code' => 'M-BTL',
            'ward_count' => 5,
        ]);

        $response = $this->actingAs($admin, 'sanctum')->post("/api/v1/admin/locations/municipalities/{$municipality->id}", [
            '_method' => 'PUT',
            'image' => UploadedFile::fake()->image('butwal.jpg'),
        ]);

        $response->assertOk();
        $municipality->refresh();
        $this->assertNotNull($municipality->image_path);
        Storage::disk('public')->assertExists($municipality->image_path);
    }

    public function test_a_non_admin_cannot_manage_locations(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')->postJson('/api/v1/admin/locations/provinces', [
            'name' => 'Test', 'code' => 'PX',
        ])->assertForbidden();
    }
}
