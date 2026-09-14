<?php

namespace Tests\Feature\Admin;

use App\Models\PlatformSecurity;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class SecurityTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        $user = User::factory()->create();
        $user->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Admin']));

        return $user;
    }

    private function superAdmin(): User
    {
        $user = User::factory()->create();
        $user->roles()->attach(Role::firstOrCreate(['key' => Role::SUPER_ADMIN], ['name' => 'Super Admin']));

        return $user;
    }

    public function test_registration_succeeds_with_no_token_when_captcha_is_not_configured(): void
    {
        $this->postJson('/api/v1/auth/register', [
            'name' => 'No Captcha Yet',
            'email' => 'nocaptcha@example.test',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ])->assertCreated();
    }

    public function test_registration_is_rejected_without_a_token_once_captcha_is_enabled(): void
    {
        PlatformSecurity::current()->update([
            'recaptcha_enabled' => true,
            'recaptcha_site_key' => 'site-key',
            'recaptcha_secret_key' => 'secret-key',
        ]);

        $this->postJson('/api/v1/auth/register', [
            'name' => 'Bot Script',
            'email' => 'bot@example.test',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ])->assertUnprocessable()->assertJsonValidationErrors('captcha_token');

        $this->assertDatabaseMissing('users', ['email' => 'bot@example.test']);
    }

    public function test_registration_succeeds_with_a_token_google_confirms_once_captcha_is_enabled(): void
    {
        PlatformSecurity::current()->update([
            'recaptcha_enabled' => true,
            'recaptcha_site_key' => 'site-key',
            'recaptcha_secret_key' => 'secret-key',
        ]);
        Http::fake(['www.google.com/recaptcha/api/siteverify' => Http::response(['success' => true])]);

        $this->postJson('/api/v1/auth/register', [
            'name' => 'Real Human',
            'email' => 'human@example.test',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'captcha_token' => 'a-real-token',
        ])->assertCreated();
    }

    public function test_registration_is_rejected_when_google_rejects_the_token(): void
    {
        PlatformSecurity::current()->update([
            'recaptcha_enabled' => true,
            'recaptcha_site_key' => 'site-key',
            'recaptcha_secret_key' => 'secret-key',
        ]);
        Http::fake(['www.google.com/recaptcha/api/siteverify' => Http::response(['success' => false])]);

        $this->postJson('/api/v1/auth/register', [
            'name' => 'Fake Token',
            'email' => 'faketoken@example.test',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'captcha_token' => 'a-fake-token',
        ])->assertUnprocessable()->assertJsonValidationErrors('captcha_token');
    }

    public function test_the_public_endpoint_reports_disabled_until_fully_configured(): void
    {
        $this->getJson('/api/v1/security/captcha')
            ->assertOk()
            ->assertJsonPath('data.enabled', false)
            ->assertJsonPath('data.site_key', null);

        PlatformSecurity::current()->update([
            'recaptcha_enabled' => true,
            'recaptcha_site_key' => 'public-site-key',
            'recaptcha_secret_key' => 'secret-key',
        ]);

        $this->getJson('/api/v1/security/captcha')
            ->assertOk()
            ->assertJsonPath('data.enabled', true)
            ->assertJsonPath('data.site_key', 'public-site-key');
    }

    public function test_a_regular_admin_cannot_view_or_change_security_settings(): void
    {
        $this->actingAs($this->admin(), 'sanctum')->getJson('/api/v1/admin/security')->assertForbidden();
        $this->actingAs($this->admin(), 'sanctum')->postJson('/api/v1/admin/security', ['recaptcha_enabled' => true])->assertForbidden();
    }

    public function test_a_super_admin_can_configure_captcha_without_ever_seeing_the_secret_echoed_back(): void
    {
        $response = $this->actingAs($this->superAdmin(), 'sanctum')->postJson('/api/v1/admin/security', [
            'recaptcha_enabled' => true,
            'recaptcha_site_key' => 'my-site-key',
            'recaptcha_secret_key' => 'my-secret-key',
        ])->assertOk();

        $response->assertJsonPath('data.recaptcha_site_key', 'my-site-key');
        $response->assertJsonPath('data.recaptcha_secret_configured', true);
        $response->assertJsonPath('data.is_active', true);
        $response->assertJsonMissingPath('data.recaptcha_secret_key');
    }

    public function test_leaving_the_secret_blank_on_update_keeps_the_existing_one(): void
    {
        $superAdmin = $this->superAdmin();
        $this->actingAs($superAdmin, 'sanctum')->postJson('/api/v1/admin/security', [
            'recaptcha_site_key' => 'key-1', 'recaptcha_secret_key' => 'original-secret',
        ]);

        $this->actingAs($superAdmin, 'sanctum')->postJson('/api/v1/admin/security', [
            'recaptcha_enabled' => true,
        ])->assertJsonPath('data.recaptcha_secret_configured', true);

        $this->assertSame('original-secret', PlatformSecurity::current()->recaptcha_secret_key);
    }

    public function test_an_admin_can_send_themself_a_test_email(): void
    {
        Mail::fake();
        $admin = $this->admin();

        $this->actingAs($admin, 'sanctum')->postJson('/api/v1/admin/mail-test')
            ->assertOk()
            ->assertJsonPath('data.sent', true)
            ->assertJsonPath('data.to', $admin->email)
            ->assertJsonPath('data.error', null);
    }
}
