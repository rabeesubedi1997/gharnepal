<?php

namespace Tests\Feature\Auth;

use App\Models\PlatformSecurity;
use App\Models\Role;
use App\Models\User;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Config;
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

    // See SecurityTest::test_registration_is_rejected_without_a_token_once_captcha_is_enabled
    // for the base "captcha blocks registration" case — these only cover the
    // mobile app's shared-secret bypass of that check.
    private function activateCaptcha(): void
    {
        PlatformSecurity::current()->update([
            'recaptcha_enabled' => true,
            'recaptcha_site_key' => 'site-key', 'recaptcha_secret_key' => 'secret-key',
        ]);
    }

    public function test_the_mobile_apps_shared_secret_header_bypasses_the_captcha_check(): void
    {
        $this->activateCaptcha();
        Config::set('services.mobile_app.shared_secret', 'the-real-secret');

        $this->withHeader('X-Mobile-App-Secret', 'the-real-secret')
            ->postJson('/api/v1/auth/register', [
                'name' => 'Sita Gurung', 'email' => 'sita@example.com',
                'password' => 'password123', 'password_confirmation' => 'password123',
            ])->assertCreated();
    }

    public function test_a_wrong_shared_secret_does_not_bypass_the_captcha_check(): void
    {
        $this->activateCaptcha();
        Config::set('services.mobile_app.shared_secret', 'the-real-secret');

        $this->withHeader('X-Mobile-App-Secret', 'a-guess')
            ->postJson('/api/v1/auth/register', [
                'name' => 'Sita Gurung', 'email' => 'sita@example.com',
                'password' => 'password123', 'password_confirmation' => 'password123',
            ])->assertUnprocessable()->assertJsonValidationErrors('captcha_token');
    }

    public function test_the_secret_header_does_nothing_when_no_shared_secret_is_configured(): void
    {
        $this->activateCaptcha();
        Config::set('services.mobile_app.shared_secret', null);

        $this->withHeader('X-Mobile-App-Secret', 'anything')
            ->postJson('/api/v1/auth/register', [
                'name' => 'Sita Gurung', 'email' => 'sita@example.com',
                'password' => 'password123', 'password_confirmation' => 'password123',
            ])->assertUnprocessable()->assertJsonValidationErrors('captcha_token');
    }
}
