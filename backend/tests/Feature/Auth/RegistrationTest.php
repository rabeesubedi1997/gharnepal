<?php

namespace Tests\Feature\Auth;

use App\Models\Role;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Auth;
use Tests\TestCase;

class RegistrationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    public function test_a_user_can_register_and_is_assigned_the_buyer_role(): void
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Sita Gurung',
            'email' => 'sita@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.email', 'sita@example.com')
            ->assertJsonPath('data.roles', [Role::BUYER]);

        $this->assertDatabaseHas('users', ['email' => 'sita@example.com']);

        $token = $response->json('token');
        $this->assertIsString($token);
        $this->assertNotEmpty($token);

        // The register endpoint also authenticated this test's client via a
        // session guard (an artifact of PHPUnit reusing one container across
        // requests within a test), whose cached user instance would otherwise
        // still be reused here (self-reporting wasRecentlyCreated). Log it out
        // so this request authenticates fresh, purely off the bearer token.
        Auth::guard('web')->logout();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/v1/auth/me')
            ->assertOk()
            ->assertJsonPath('data.email', 'sita@example.com');
    }

    public function test_registration_requires_a_unique_email(): void
    {
        User::factory()->create(['email' => 'taken@example.com']);

        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Someone Else',
            'email' => 'taken@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertUnprocessable()->assertJsonValidationErrors('email');
    }

    public function test_registration_requires_matching_password_confirmation(): void
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'Someone',
            'email' => 'someone@example.com',
            'password' => 'password123',
            'password_confirmation' => 'not-matching',
        ]);

        $response->assertUnprocessable()->assertJsonValidationErrors('password');
    }
}
