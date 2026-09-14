<?php

namespace App\Http\Controllers\Api\V1\Public;

use App\Http\Controllers\Controller;
use App\Models\PlatformSecurity;
use Illuminate\Http\JsonResponse;

/**
 * Public, unauthenticated — the registration form asks this whether to
 * render the "I'm not a robot" widget at all, and with which site key.
 * Only ever exposes the site key (meant to be public); the secret key
 * never leaves the server.
 */
class SecurityController extends Controller
{
    public function captcha(): JsonResponse
    {
        $security = PlatformSecurity::current();
        $active = $security->captchaIsActive();

        return response()->json([
            'data' => [
                'enabled' => $active,
                'site_key' => $active ? $security->recaptcha_site_key : null,
            ],
        ]);
    }
}
