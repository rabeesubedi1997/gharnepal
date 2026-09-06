<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Http\Controllers\Controller;
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

class AuthController extends Controller
{
    public function register(RegisterRequest $request): JsonResponse
    {
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

        return (new UserResource($user->load('roles')))->response()->setStatusCode(201);
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

        return new UserResource($request->user()->load('roles'));
    }

    public function logout(Request $request): JsonResponse
    {
        Auth::guard('web')->logout();

        if ($request->hasSession()) {
            $request->session()->invalidate();
            $request->session()->regenerateToken();
        }

        return response()->json(['message' => 'Logged out.']);
    }

    public function me(Request $request): UserResource
    {
        return new UserResource($request->user()->load('roles'));
    }
}
