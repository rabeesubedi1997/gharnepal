<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class LoginTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_user_can_log_in_with_correct_credentials(): void
    {
        $user = User::factory()->create([
            'email' => 'ram@example.com',
            'password' => Hash::make('correct-password'),
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'ram@example.com',
            'password' => 'correct-password',
        ]);

        $response->assertOk()->assertJsonPath('data.id', $user->id);
    }

    public function test_login_returns_a_bearer_token_a_native_client_can_use(): void
    {
        $user = User::factory()->create([
            'email' => 'ram@example.com',
            'password' => Hash::make('correct-password'),
        ]);

        $login = $this->postJson('/api/v1/auth/login', [
            'email' => 'ram@example.com',
            'password' => 'correct-password',
        ]);

        $login->assertOk();
        $token = $login->json('token');
        $this->assertIsString($token);
        $this->assertNotEmpty($token);

        // The login call above also authenticated this test's client via a
        // session guard (an artifact of PHPUnit reusing one container across
        // requests within a test — a real per-request process never carries
        // this over). Log it out so this request authenticates fresh, purely
        // off the bearer token, like a real native client would.
        Auth::guard('web')->logout();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/v1/auth/me')
            ->assertOk()
            ->assertJsonPath('data.id', $user->id);
    }

    public function test_logout_revokes_the_bearer_token_it_was_called_with(): void
    {
        User::factory()->create([
            'email' => 'ram@example.com',
            'password' => Hash::make('correct-password'),
        ]);

        $token = $this->postJson('/api/v1/auth/login', [
            'email' => 'ram@example.com',
            'password' => 'correct-password',
        ])->json('token');

        // The login call above also authenticated this test's client via a
        // session guard (an artifact of PHPUnit reusing one container across
        // requests within a test — a real per-request process never carries
        // this over). Log it out so the next request authenticates fresh,
        // purely off the bearer token, like a real native client would.
        Auth::guard('web')->logout();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/v1/auth/logout')
            ->assertOk();

        // The logout request above resolved and cached a user on the sanctum
        // guard before deleting its token; forget that cached resolution too
        // so this next check looks the token up in the database again rather
        // than reusing the (now stale) in-memory result.
        Auth::forgetGuards();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/v1/auth/me')
            ->assertUnauthorized();
    }

    public function test_login_fails_with_incorrect_password(): void
    {
        User::factory()->create([
            'email' => 'ram@example.com',
            'password' => Hash::make('correct-password'),
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'ram@example.com',
            'password' => 'wrong-password',
        ]);

        $response->assertUnprocessable()->assertJsonValidationErrors('email');
    }

    public function test_an_authenticated_user_can_be_logged_out(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/v1/auth/logout');

        $response->assertOk();
    }

    public function test_guests_cannot_access_the_me_endpoint(): void
    {
        $this->getJson('/api/v1/auth/me')->assertUnauthorized();
    }
}
