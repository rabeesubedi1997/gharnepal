<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
use App\Domain\Identity\Services\RecaptchaVerifier;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Resources\UserResource;
use App\Models\Role;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use Laravel\Sanctum\PersonalAccessToken;

class AuthController extends Controller
{
    public function __construct(private readonly RecaptchaVerifier $recaptcha) {}

    public function register(RegisterRequest $request): JsonResponse
    {
        // A no-op the moment nothing is configured (PlatformSecurity) — this
        // is the actual fix for "a script can create unlimited accounts",
        // not just validation the form already did. The mobile app has no
        // way to render the web "I'm not a robot" widget, so it identifies
        // itself with a build-time shared secret instead — see
        // config('services.mobile_app.shared_secret').
        if (! $this->isTrustedMobileApp($request)
            && ! $this->recaptcha->verify($request->validated('captcha_token'), $request->ip())) {
            throw ValidationException::withMessages([
                'captcha_token' => 'Please complete the "I\'m not a robot" check.',
            ]);
        }

        $user = User::create([
            'name' => $request->validated('name'),
            'email' => $request->validated('email'),
            'phone' => $request->validated('phone'),
            'password' => Hash::make($request->validated('password')),
        ]);

        $user->roles()->syncWithoutDetaching(Role::where('key', Role::BUYER)->pluck('id'));
        $user->refresh();

        Auth::login($user);

        // Session is only started for requests Sanctum treats as "stateful"
        // (matching SANCTUM_STATEFUL_DOMAINS, i.e. our SPA's origin). A token
        // based client hitting this same endpoint has no session to regenerate.
        if ($request->hasSession()) {
            $request->session()->regenerate();
        }

        // Always issue a personal access token alongside the session: the web
        // SPA ignores it and keeps using its cookie, while a native client
        // (which has no session to speak of) uses it as a Bearer token.
        $token = $user->createToken('mobile')->plainTextToken;

        return (new UserResource($user->load('roles', 'agencies')))
            ->additional(['token' => $token])
            ->response()->setStatusCode(201);
    }

    public function login(LoginRequest $request): UserResource
    {
        if (! Auth::attempt($request->only('email', 'password'), true)) {
            throw ValidationException::withMessages([
                'email' => __('auth.failed'),
            ]);
        }

        if (Auth::user()->status === 'suspended') {
            Auth::logout();

            throw ValidationException::withMessages([
                'email' => 'This account has been suspended. Contact support if you believe this is a mistake.',
            ]);
        }

        if ($request->hasSession()) {
            $request->session()->regenerate();
        }

        $user = $request->user();
        $token = $user->createToken('mobile')->plainTextToken;

        return (new UserResource($user->load('roles', 'agencies')))->additional(['token' => $token]);
    }

    public function logout(Request $request): JsonResponse
    {
        // The web SPA authenticates via a session-backed TransientToken,
        // which carries no database row to revoke; only a native client's
        // real PersonalAccessToken (the bearer token it sent) needs deleting.
        $token = $request->user()?->currentAccessToken();
        if ($token instanceof PersonalAccessToken) {
            $token->delete();
        }

        Auth::guard('web')->logout();

        if ($request->hasSession()) {
            $request->session()->invalidate();
            $request->session()->regenerateToken();
        }

        return response()->json(['message' => 'Logged out.']);
    }

    public function me(Request $request): UserResource
    {
        return new UserResource($request->user()->load('roles', 'agencies'));
    }

    /**
     * True only when the caller sent the exact shared secret compiled into
     * the official mobile app, via `X-Mobile-App-Secret`. `hash_equals`
     * guards against a timing attack revealing the secret byte by byte;
     * an unset `shared_secret` (not configured) always returns false rather
     * than matching an empty header, which would otherwise defeat the check
     * entirely.
     */
    private function isTrustedMobileApp(Request $request): bool
    {
        $configured = config('services.mobile_app.shared_secret');
        $provided = $request->header('X-Mobile-App-Secret');

        if (! $configured || ! $provided) {
            return false;
        }

        return hash_equals($configured, $provided);
    }
}
