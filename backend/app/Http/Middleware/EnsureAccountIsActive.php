<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
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
        $user = $request->user();

        if ($user && $user->status === 'suspended') {
            abort(403, 'This account has been suspended.');
        }

        return $next($request);
    }
}
