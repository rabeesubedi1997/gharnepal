<?php

namespace App\Domain\Identity\Services;

use App\Models\PlatformSecurity;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Google reCAPTCHA v2 ("I'm not a robot") verification against whatever
 * site/secret key the admin has configured (see PlatformSecurity, Admin\
 * SecurityController). Nothing currently stood between a script and
 * unlimited account creation — this is the check for that, wired into
 * registration (AuthController::register); reusable for any other endpoint
 * that turns out to need the same protection later.
 */
class RecaptchaVerifier
{
    private const VERIFY_URL = 'https://www.google.com/recaptcha/api/siteverify';

    /**
     * True when the check passes OR isn't actually configured yet (a
     * half-set-up captcha must never lock real users out — see
     * PlatformSecurity::captchaIsActive()). False only for a real,
     * configured, failed/missing-token verification.
     */
    public function verify(?string $token, ?string $ip): bool
    {
        $security = PlatformSecurity::current();

        if (! $security->captchaIsActive()) {
            return true;
        }

        if (! $token) {
            return false;
        }

        try {
            $response = Http::asForm()->timeout(6)->post(self::VERIFY_URL, [
                'secret' => $security->recaptcha_secret_key,
                'response' => $token,
                'remoteip' => $ip,
            ]);

            return (bool) $response->json('success');
        } catch (\Throwable $e) {
            // Google's endpoint being briefly unreachable shouldn't be
            // indistinguishable from "yes, this really is a bot" — but it
            // must still fail closed (return false), just with a clear log
            // line instead of a silent, unexplained rejection.
            Log::warning('reCAPTCHA verification request failed', ['error' => $e->getMessage()]);

            return false;
        }
    }
}
