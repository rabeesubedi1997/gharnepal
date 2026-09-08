<?php

namespace Tests\Feature\Admin;

use App\Models\Agency;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Auth;
use Tests\TestCase;

class AdminConsoleTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        $admin = User::factory()->create();
        $admin->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']));

        return $admin;
    }

    // --- Dashboard stats ---

    public function test_admin_can_view_dashboard_stats(): void
    {
        $admin = $this->admin();

        $response = $this->actingAs($admin, 'sanctum')->getJson('/api/v1/admin/dashboard/stats');

        $response->assertOk()
            ->assertJsonStructure(['data' => ['listings', 'users', 'agencies', 'moderation_queue', 'payments']])
            ->assertJsonPath('data.users.total', 1); // just the admin so far
    }

    public function test_a_non_admin_cannot_view_dashboard_stats(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')->getJson('/api/v1/admin/dashboard/stats')->assertForbidden();
    }

    // --- User management ---

    public function test_admin_can_search_and_filter_users(): void
    {
        $admin = $this->admin();
        $target = User::factory()->create(['name' => 'Findable Person', 'email' => 'findable@example.com']);
        $target->roles()->attach(Role::firstOrCreate(['key' => Role::OWNER], ['name' => 'Owner']));
        User::factory()->create(['name' => 'Someone Else']);

        $response = $this->actingAs($admin, 'sanctum')->getJson('/api/v1/admin/users?q=Findable');

        $response->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.email', 'findable@example.com');
    }

    public function test_admin_can_suspend_a_user(): void
    {
        $admin = $this->admin();
        $target = User::factory()->create();

        $this->actingAs($admin, 'sanctum')->patchJson("/api/v1/admin/users/{$target->id}/status", [
            'status' => 'suspended',
        ])->assertOk()->assertJsonPath('data.status', 'suspended');
    }

    public function test_a_suspended_user_cannot_log_in(): void
    {
        // Suspension has real teeth, not just a flag — set status directly
        // (mirroring what the admin endpoint above persists) and confirm the
        // login endpoint itself rejects it, with no actingAs() in this test
        // to keep the default auth guard untouched for a real Auth::attempt().
        $target = User::factory()->create(['password' => 'password', 'status' => 'suspended']);

        $this->postJson('/api/v1/auth/login', [
            'email' => $target->email,
            'password' => 'password',
        ])->assertUnprocessable();
    }

    public function test_a_suspended_users_existing_session_is_blocked_from_protected_routes(): void
    {
        $admin = $this->admin();
        $target = User::factory()->create();

        // Confirm access works before suspension.
        $this->actingAs($target, 'sanctum')->getJson('/api/v1/account/favorites')->assertOk();

        $this->actingAs($admin, 'sanctum')->patchJson("/api/v1/admin/users/{$target->id}/status", ['status' => 'suspended'])
            ->assertOk();

        // Re-fetch: a real session re-resolves the user from the DB on every
        // request, so it's the DB state that must reflect suspension — not
        // the in-memory $target object from before the admin's update.
        $this->actingAs($target->fresh(), 'sanctum')->getJson('/api/v1/account/favorites')->assertForbidden();
    }

    public function test_a_suspended_users_bearer_token_is_blocked_from_protected_routes(): void
    {
        // The test above uses actingAs(), which calls Auth::shouldUse()
        // itself and would mask the real bug: EnsureAccountIsActive is
        // registered on the global middleware stack, which runs before
        // route/group middleware (including auth:sanctum) ever resolves the
        // guard — so $request->user() there needs the sanctum guard asked
        // for explicitly, or a real bearer-token client's suspension check
        // is silently inert on every route in the app. A genuine bearer
        // request is the only way to catch that.
        $admin = $this->admin();
        $target = User::factory()->create();
        $token = $target->createToken('test')->plainTextToken;

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/v1/account/favorites')
            ->assertOk();

        // The sanctum guard caches its resolved user for the rest of this
        // *test's* container (an artifact of PHPUnit reusing one container
        // across requests within a test — a real bearer-token client is a
        // fresh process every time and never carries this over). Forget it
        // so the next request re-resolves from the database and actually
        // sees the suspension.
        Auth::forgetGuards();

        $this->actingAs($admin, 'sanctum')->patchJson("/api/v1/admin/users/{$target->id}/status", ['status' => 'suspended'])
            ->assertOk();

        Auth::forgetGuards();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/v1/account/favorites')
            ->assertForbidden();
    }

    public function test_admin_cannot_suspend_their_own_account(): void
    {
        $admin = $this->admin();

        $this->actingAs($admin, 'sanctum')->patchJson("/api/v1/admin/users/{$admin->id}/status", [
            'status' => 'suspended',
        ])->assertUnprocessable();
    }

    public function test_admin_can_update_a_users_roles(): void
    {
        $admin = $this->admin();
        $target = User::factory()->create();
        Role::firstOrCreate(['key' => Role::OWNER], ['name' => 'Owner']);
        Role::firstOrCreate(['key' => Role::AGENT], ['name' => 'Agent']);

        $response = $this->actingAs($admin, 'sanctum')->putJson("/api/v1/admin/users/{$target->id}/roles", [
            'roles' => [Role::OWNER, Role::AGENT],
        ]);

        $response->assertOk();
        $this->assertEqualsCanonicalizing([Role::OWNER, Role::AGENT], $response->json('data.roles'));
    }

    public function test_admin_cannot_remove_their_own_admin_role(): void
    {
        $admin = $this->admin();
        Role::firstOrCreate(['key' => Role::BUYER], ['name' => 'Buyer']);

        $this->actingAs($admin, 'sanctum')->putJson("/api/v1/admin/users/{$admin->id}/roles", [
            'roles' => [Role::BUYER],
        ])->assertUnprocessable();
    }

    public function test_a_non_admin_cannot_manage_users(): void
    {
        $user = User::factory()->create();
        $target = User::factory()->create();

        $this->actingAs($user, 'sanctum')->getJson('/api/v1/admin/users')->assertForbidden();
        $this->actingAs($user, 'sanctum')->patchJson("/api/v1/admin/users/{$target->id}/status", ['status' => 'suspended'])->assertForbidden();
    }

    // --- Agency verification ---

    public function test_admin_can_view_all_agencies_regardless_of_status(): void
    {
        $admin = $this->admin();
        Agency::create(['name' => 'Pending Co', 'slug' => 'pending-co', 'status' => 'pending']);
        Agency::create(['name' => 'Active Co', 'slug' => 'active-co', 'status' => 'active', 'verified_at' => now()]);

        $response = $this->actingAs($admin, 'sanctum')->getJson('/api/v1/admin/agencies');

        $response->assertOk()->assertJsonCount(2, 'data');
    }

    public function test_admin_can_verify_a_pending_agency(): void
    {
        $admin = $this->admin();
        $agency = Agency::create(['name' => 'New Agency', 'slug' => 'new-agency', 'status' => 'pending']);

        $response = $this->actingAs($admin, 'sanctum')->patchJson("/api/v1/admin/agencies/{$agency->id}/verify");

        $response->assertOk()
            ->assertJsonPath('data.status', 'active')
            ->assertJsonPath('data.is_verified', true);

        // And it now appears in the public directory.
        $this->getJson('/api/v1/agencies')->assertJsonFragment(['name' => 'New Agency']);
    }

    public function test_admin_can_suspend_a_previously_verified_agency_and_it_leaves_the_public_directory(): void
    {
        $admin = $this->admin();
        $agency = Agency::create(['name' => 'Rogue Agency', 'slug' => 'rogue-agency', 'status' => 'active', 'verified_at' => now()]);

        $this->actingAs($admin, 'sanctum')->patchJson("/api/v1/admin/agencies/{$agency->id}/suspend")
            ->assertOk()
            ->assertJsonPath('data.status', 'suspended')
            ->assertJsonPath('data.is_verified', false);

        $this->getJson('/api/v1/agencies')->assertJsonMissing(['name' => 'Rogue Agency']);
    }

    public function test_a_non_admin_cannot_manage_agencies(): void
    {
        $user = User::factory()->create();
        $agency = Agency::create(['name' => 'X', 'slug' => 'x-agency', 'status' => 'pending']);

        $this->actingAs($user, 'sanctum')->getJson('/api/v1/admin/agencies')->assertForbidden();
        $this->actingAs($user, 'sanctum')->patchJson("/api/v1/admin/agencies/{$agency->id}/verify")->assertForbidden();
    }
}
