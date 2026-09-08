<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

/**
 * Applied globally so a suspension actually has teeth: it blocks not just a
 * fresh login (see AuthController::login) but every subsequent authenticated
 * request from a session/token that was already active when an admin
 * suspended the account. A no-op for guests — status only matters once
 * someone is authenticated.
 */
class EnsureAccountIsActive
{
    public function handle(Request $request, Closure $next): Response
    {
        // Auth::guard('sanctum')->user(), not $request->user(): this
        // middleware sits on the global stack, which runs before routing —
        // $request->user() resolves through a closure that Request only
        // gets wired up to the real AuthManager via a container "rebinding"
        // callback, and that hasn't necessarily fired for this request yet
        // at this point in the pipeline, so it silently returns null
        // regardless of which guard name is passed. Asking the AuthManager
        // directly works correctly this early and checks both the web
        // SPA's session and a bearer token, exactly like any other route.
        $user = Auth::guard('sanctum')->user();

        if ($user && $user->status === 'suspended') {
            abort(403, 'This account has been suspended.');
        }

        return $next($request);
    }
}
