<?php

namespace Tests\Feature\Admin;

use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * A real two-tier admin system: any 'admin' can do everything the console
 * offers except grant/revoke admin access itself (and refund payments,
 * covered in FeaturedListingPurchaseTest instead) — those two are reserved
 * to 'super_admin'. See LeadRoutingService's sibling concept here,
 * User::isAdmin()/isSuperAdmin(), and Admin\UserController's role-change guard.
 */
class SuperAdminTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        $admin = User::factory()->create();
        $admin->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']));

        return $admin;
    }

    private function superAdmin(): User
    {
        $superAdmin = User::factory()->create();
        $superAdmin->roles()->attach(Role::firstOrCreate(['key' => Role::SUPER_ADMIN], ['name' => 'Super Admin']));

        return $superAdmin;
    }

    public function test_a_super_admin_passes_every_regular_admin_gate_too(): void
    {
        $superAdmin = $this->superAdmin();

        $this->actingAs($superAdmin, 'sanctum')->getJson('/api/v1/admin/dashboard/stats')->assertOk();
        $this->actingAs($superAdmin, 'sanctum')->getJson('/api/v1/admin/users')->assertOk();
    }

    public function test_a_regular_admin_can_still_edit_non_privileged_roles(): void
    {
        $admin = $this->admin();
        $target = User::factory()->create();
        Role::firstOrCreate(['key' => Role::OWNER], ['name' => 'Owner']);
        Role::firstOrCreate(['key' => Role::AGENT], ['name' => 'Agent']);

        $this->actingAs($admin, 'sanctum')->putJson("/api/v1/admin/users/{$target->id}/roles", [
            'roles' => [Role::OWNER, Role::AGENT],
        ])->assertOk();
    }

    public function test_a_regular_admin_cannot_grant_the_admin_role_to_someone_else(): void
    {
        $admin = $this->admin();
        $target = User::factory()->create();
        Role::firstOrCreate(['key' => Role::BUYER], ['name' => 'Buyer']);

        $this->actingAs($admin, 'sanctum')->putJson("/api/v1/admin/users/{$target->id}/roles", [
            'roles' => [Role::BUYER, Role::ADMIN],
        ])->assertUnprocessable();

        $this->assertDatabaseMissing('role_user', ['user_id' => $target->id]);
    }

    public function test_a_regular_admin_cannot_revoke_another_admins_role(): void
    {
        $admin = $this->admin();
        $otherAdmin = $this->admin();
        Role::firstOrCreate(['key' => Role::BUYER], ['name' => 'Buyer']);

        $this->actingAs($admin, 'sanctum')->putJson("/api/v1/admin/users/{$otherAdmin->id}/roles", [
            'roles' => [Role::BUYER],
        ])->assertUnprocessable();

        $this->assertTrue($otherAdmin->fresh()->isAdmin());
    }

    public function test_a_super_admin_can_grant_and_revoke_admin_access(): void
    {
        $superAdmin = $this->superAdmin();
        $target = User::factory()->create();
        Role::firstOrCreate(['key' => Role::BUYER], ['name' => 'Buyer']);
        Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']);

        $this->actingAs($superAdmin, 'sanctum')->putJson("/api/v1/admin/users/{$target->id}/roles", [
            'roles' => [Role::ADMIN],
        ])->assertOk();
        $this->assertTrue($target->fresh()->isAdmin());

        $this->actingAs($superAdmin, 'sanctum')->putJson("/api/v1/admin/users/{$target->id}/roles", [
            'roles' => [Role::BUYER],
        ])->assertOk();
        $this->assertFalse($target->fresh()->isAdmin());
    }

    public function test_a_regular_admin_can_create_a_user_without_admin_access(): void
    {
        $admin = $this->admin();
        Role::firstOrCreate(['key' => Role::OWNER], ['name' => 'Owner']);

        $response = $this->actingAs($admin, 'sanctum')->postJson('/api/v1/admin/users', [
            'name' => 'New Owner',
            'email' => 'new-owner@example.com',
            'password' => 'password123',
            'roles' => [Role::OWNER],
        ]);

        $response->assertCreated()->assertJsonPath('data.email', 'new-owner@example.com');
        $this->assertDatabaseHas('users', ['email' => 'new-owner@example.com', 'status' => 'active']);
    }

    public function test_a_regular_admin_cannot_create_a_user_with_admin_access(): void
    {
        $admin = $this->admin();

        $this->actingAs($admin, 'sanctum')->postJson('/api/v1/admin/users', [
            'name' => 'Sneaky',
            'email' => 'sneaky@example.com',
            'password' => 'password123',
            'roles' => [Role::ADMIN],
        ])->assertUnprocessable();

        $this->assertDatabaseMissing('users', ['email' => 'sneaky@example.com']);
    }

    public function test_a_super_admin_can_create_a_user_with_admin_access(): void
    {
        $superAdmin = $this->superAdmin();
        Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']);

        $response = $this->actingAs($superAdmin, 'sanctum')->postJson('/api/v1/admin/users', [
            'name' => 'New Admin',
            'email' => 'new-admin@example.com',
            'password' => 'password123',
            'roles' => [Role::ADMIN],
        ]);

        $response->assertCreated();
        $newAdmin = User::where('email', 'new-admin@example.com')->firstOrFail();
        $this->assertTrue($newAdmin->isAdmin());
        $this->assertFalse($newAdmin->isSuperAdmin());
    }

    public function test_creating_a_user_with_a_duplicate_email_fails(): void
    {
        $admin = $this->admin();
        $existing = User::factory()->create();
        Role::firstOrCreate(['key' => Role::BUYER], ['name' => 'Buyer']);

        $this->actingAs($admin, 'sanctum')->postJson('/api/v1/admin/users', [
            'name' => 'Duplicate',
            'email' => $existing->email,
            'password' => 'password123',
            'roles' => [Role::BUYER],
        ])->assertUnprocessable();
    }

    public function test_a_non_admin_cannot_create_users(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')->postJson('/api/v1/admin/users', [
            'name' => 'X',
            'email' => 'x@example.com',
            'password' => 'password123',
            'roles' => [Role::BUYER],
        ])->assertForbidden();
    }
}
