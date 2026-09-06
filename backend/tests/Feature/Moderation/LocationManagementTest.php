<?php

namespace Tests\Feature\Moderation;

use App\Models\Province;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LocationManagementTest extends TestCase
{
    use RefreshDatabase;

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

    public function test_a_non_admin_cannot_manage_locations(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')->postJson('/api/v1/admin/locations/provinces', [
            'name' => 'Test', 'code' => 'PX',
        ])->assertForbidden();
    }
}
