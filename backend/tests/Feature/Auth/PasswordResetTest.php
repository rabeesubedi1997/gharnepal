<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Password;
use Tests\TestCase;

class PasswordResetTest extends TestCase
{
    use RefreshDatabase;

    public function test_requesting_a_reset_link_sends_a_notification_pointing_at_the_frontend(): void
    {
        Notification::fake();
        $user = User::factory()->create(['email' => 'ram@example.com']);

        $this->postJson('/api/v1/auth/password/forgot', ['email' => 'ram@example.com'])->assertOk();

        Notification::assertSentTo($user, ResetPassword::class, function (ResetPassword $notification) use ($user) {
            $url = $notification->toMail($user)->actionUrl;

            return str_contains($url, config('app.frontend_url').'/reset-password')
                && str_contains($url, 'token=')
                && str_contains($url, 'email=ram%40example.com');
        });
    }

    public function test_requesting_a_reset_link_for_an_unknown_email_still_returns_a_generic_message(): void
    {
        Notification::fake();

        // Same response either way — a distinguishable one would let anyone
        // enumerate which emails have accounts.
        $this->postJson('/api/v1/auth/password/forgot', ['email' => 'nobody@example.com'])
            ->assertOk()
            ->assertJsonPath('message', 'If an account exists for that email, a password reset link has been sent.');

        Notification::assertNothingSent();
    }

    public function test_a_user_can_reset_their_password_with_a_valid_token(): void
    {
        $user = User::factory()->create(['email' => 'ram@example.com', 'password' => Hash::make('old-password')]);
        $token = Password::createToken($user);

        $this->postJson('/api/v1/auth/password/reset', [
            'token' => $token,
            'email' => 'ram@example.com',
            'password' => 'new-password-123',
            'password_confirmation' => 'new-password-123',
        ])->assertOk();

        $this->assertTrue(Hash::check('new-password-123', $user->fresh()->password));
    }

    public function test_resetting_the_password_revokes_existing_bearer_tokens(): void
    {
        $user = User::factory()->create(['email' => 'ram@example.com', 'password' => Hash::make('old-password')]);
        $user->createToken('mobile');
        $this->assertCount(1, $user->tokens);

        $token = Password::createToken($user);

        $this->postJson('/api/v1/auth/password/reset', [
            'token' => $token,
            'email' => 'ram@example.com',
            'password' => 'new-password-123',
            'password_confirmation' => 'new-password-123',
        ])->assertOk();

        $this->assertCount(0, $user->fresh()->tokens);
    }

    public function test_an_invalid_token_is_rejected(): void
    {
        User::factory()->create(['email' => 'ram@example.com']);

        $this->postJson('/api/v1/auth/password/reset', [
            'token' => 'not-a-real-token',
            'email' => 'ram@example.com',
            'password' => 'new-password-123',
            'password_confirmation' => 'new-password-123',
        ])->assertUnprocessable();
    }

    public function test_mismatched_password_confirmation_is_rejected(): void
    {
        $user = User::factory()->create(['email' => 'ram@example.com']);
        $token = Password::createToken($user);

        $this->postJson('/api/v1/auth/password/reset', [
            'token' => $token,
            'email' => 'ram@example.com',
            'password' => 'new-password-123',
            'password_confirmation' => 'does-not-match',
        ])->assertUnprocessable();
    }
}
