<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class ProfileTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_user_can_update_their_name(): void
    {
        $user = User::factory()->create(['name' => 'Old Name']);

        $response = $this->actingAs($user, 'sanctum')->putJson('/api/v1/account/profile', [
            'name' => 'New Name',
        ]);

        $response->assertOk()->assertJsonPath('data.name', 'New Name');
        $this->assertSame('New Name', $user->fresh()->name);
    }

    public function test_a_name_is_required(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')->putJson('/api/v1/account/profile', ['name' => ''])
            ->assertUnprocessable()->assertJsonValidationErrors('name');
    }

    public function test_a_user_can_change_their_password_with_the_correct_current_password(): void
    {
        $user = User::factory()->create(['password' => Hash::make('old-password')]);

        $response = $this->actingAs($user, 'sanctum')->putJson('/api/v1/account/password', [
            'current_password' => 'old-password',
            'password' => 'new-password-123',
            'password_confirmation' => 'new-password-123',
        ]);

        $response->assertOk();
        $this->assertTrue(Hash::check('new-password-123', $user->fresh()->password));
    }

    public function test_the_current_password_must_be_correct(): void
    {
        $user = User::factory()->create(['password' => Hash::make('old-password')]);

        $response = $this->actingAs($user, 'sanctum')->putJson('/api/v1/account/password', [
            'current_password' => 'wrong-password',
            'password' => 'new-password-123',
            'password_confirmation' => 'new-password-123',
        ]);

        $response->assertUnprocessable()->assertJsonValidationErrors('current_password');
        $this->assertTrue(Hash::check('old-password', $user->fresh()->password));
    }

    public function test_the_new_password_must_be_confirmed(): void
    {
        $user = User::factory()->create(['password' => Hash::make('old-password')]);

        $this->actingAs($user, 'sanctum')->putJson('/api/v1/account/password', [
            'current_password' => 'old-password',
            'password' => 'new-password-123',
            'password_confirmation' => 'does-not-match',
        ])->assertUnprocessable()->assertJsonValidationErrors('password');
    }

    public function test_guests_cannot_update_a_profile(): void
    {
        $this->putJson('/api/v1/account/profile', ['name' => 'X'])->assertUnauthorized();
    }
}
