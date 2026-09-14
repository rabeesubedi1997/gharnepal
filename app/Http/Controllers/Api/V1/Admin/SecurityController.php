<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\PlatformSecurity;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Both read and write are reserved to a super admin (routes/api.php) — the
 * secret key is a real credential, unlike branding's site name/favicon, so
 * this doesn't follow the "any admin can view" pattern Branding does.
 */
class SecurityController extends Controller
{
    public function show(): JsonResponse
    {
        return $this->respond(PlatformSecurity::current());
    }

    public function update(Request $request): JsonResponse
    {
        $data = $request->validate([
            'recaptcha_enabled' => ['sometimes', 'boolean'],
            'recaptcha_site_key' => ['sometimes', 'nullable', 'string', 'max:255'],
            // Blank/omitted keeps the existing secret — a super admin
            // shouldn't have to know & retype it just to flip site_key or
            // the enabled toggle.
            'recaptcha_secret_key' => ['sometimes', 'nullable', 'string', 'max:255'],
        ]);

        $security = PlatformSecurity::current();

        if (array_key_exists('recaptcha_secret_key', $data) && ! $data['recaptcha_secret_key']) {
            unset($data['recaptcha_secret_key']);
        }

        $security->update($data);

        return $this->respond($security->fresh());
    }

    private function respond(PlatformSecurity $security): JsonResponse
    {
        return response()->json([
            'data' => [
                'recaptcha_enabled' => $security->recaptcha_enabled,
                'recaptcha_site_key' => $security->recaptcha_site_key,
                'recaptcha_secret_configured' => (bool) $security->recaptcha_secret_key,
                'is_active' => $security->captchaIsActive(),
            ],
        ]);
    }
}
