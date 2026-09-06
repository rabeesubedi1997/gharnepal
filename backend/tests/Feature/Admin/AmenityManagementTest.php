<?php

namespace Tests\Feature\Admin;

use App\Models\Amenity;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AmenityManagementTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        $admin = User::factory()->create();
        $admin->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']));

        return $admin;
    }

    public function test_admin_can_create_an_amenity(): void
    {
        $admin = $this->admin();

        $response = $this->actingAs($admin, 'sanctum')->postJson('/api/v1/admin/amenities', [
            'key' => 'rooftop_access',
            'name' => 'Rooftop access',
            'category' => 'outdoor',
        ]);

        $response->assertCreated()->assertJsonPath('data.key', 'rooftop_access');
        $this->assertDatabaseHas('amenities', ['key' => 'rooftop_access']);
    }

    public function test_admin_can_update_and_delete_an_amenity(): void
    {
        $admin = $this->admin();
        $amenity = Amenity::create(['key' => 'test_amenity', 'name' => 'Test amenity']);

        $this->actingAs($admin, 'sanctum')->putJson("/api/v1/admin/amenities/{$amenity->id}", [
            'name' => 'Renamed amenity',
        ])->assertOk()->assertJsonPath('data.name', 'Renamed amenity');

        $this->actingAs($admin, 'sanctum')->deleteJson("/api/v1/admin/amenities/{$amenity->id}")->assertNoContent();
        $this->assertDatabaseMissing('amenities', ['id' => $amenity->id]);
    }

    public function test_a_duplicate_amenity_key_is_rejected(): void
    {
        $admin = $this->admin();
        Amenity::create(['key' => 'existing_key', 'name' => 'Existing']);

        $this->actingAs($admin, 'sanctum')->postJson('/api/v1/admin/amenities', [
            'key' => 'existing_key',
            'name' => 'Duplicate',
        ])->assertUnprocessable();
    }

    public function test_a_non_admin_cannot_manage_amenities(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')->postJson('/api/v1/admin/amenities', [
            'key' => 'x', 'name' => 'X',
        ])->assertForbidden();
    }
}
