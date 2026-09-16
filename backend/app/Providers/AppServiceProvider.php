<?php

namespace App\Providers;

use App\Domain\Identity\Contracts\OtpSender;
use App\Domain\Identity\Services\LogOtpSender;
use App\Domain\Notifications\Contracts\PushSender;
use App\Domain\Notifications\Services\WebPushSender;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->bind(OtpSender::class, LogOtpSender::class);

        // Real Web Push (browser notifications), not a stub — needs no
        // external account, unlike SMS/mobile FCM push.
        $this->app->bind(PushSender::class, WebPushSender::class);

        // Payment gateways are no longer a single container binding — an
        // admin can configure any number of them (PaymentGatewayConfig,
        // Admin\PaymentGatewayConfigController) and one is chosen per
        // checkout, resolved via PaymentGatewayDriverRegistry. The sandbox
        // driver still refuses to run in production without
        // PAYMENT_GATEWAY_ALLOW_SANDBOX_IN_PRODUCTION=true — see
        // SandboxGatewayDriver::initiate().
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // General API traffic — generous, but not unlimited. Keyed by user
        // when authenticated so one heavy user can't starve another; by IP
        // for guests (search/browse is the main guest-accessible surface).
        RateLimiter::for('api', function (Request $request) {
            return Limit::perMinute(120)->by($request->user()?->id ?: $request->ip());
        });

        // Login/register: brute-force and credential-stuffing protection.
        // Keyed by IP (not email) so an attacker can't just rotate emails to
        // dodge the limit, and a shared office/NAT IP isn't punished for one
        // bad actor at the tight end — 10/min is still well above any real
        // user's genuine retry rate.
        RateLimiter::for('auth', function (Request $request) {
            return Limit::perMinute(10)->by($request->ip());
        });

        // OTP request: this is the actual cooldown — at most one new code
        // every 30s per account, so a phone can't be SMS-bombed and an
        // attacker can't keep minting fresh 5-attempt budgets at will.
        RateLimiter::for('otp-request', function (Request $request) {
            return Limit::perSecond(1, 30)->by($request->user()?->id ?: $request->ip());
        });

        // OTP verify: separate from -request since it's a different abuse
        // shape (guessing a code you already have), a bit more headroom.
        RateLimiter::for('otp-verify', function (Request $request) {
            return Limit::perMinute(10)->by($request->user()?->id ?: $request->ip());
        });

        // AI assistant chat: no external API cost to worry about (rule-based
        // parser, not an LLM), but each message still runs a DB search, so
        // still worth bounding — keyed by guest_token/user when present so
        // one real conversation isn't cut off by a shared office IP.
        RateLimiter::for('assistant', function (Request $request) {
            return Limit::perMinute(30)->by($request->user('sanctum')?->id ?: $request->input('guest_token') ?: $request->ip());
        });

        // Password reset emails link to the SPA, not this API — there's no
        // backend page for a user to land on. See PasswordResetController.
        ResetPassword::createUrlUsing(function ($notifiable, string $token) {
            return sprintf(
                '%s/reset-password?token=%s&email=%s',
                config('app.frontend_url'),
                $token,
                urlencode($notifiable->getEmailForPasswordReset()),
            );
        });
    }
}
