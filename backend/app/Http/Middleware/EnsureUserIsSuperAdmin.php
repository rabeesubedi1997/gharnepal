<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/** Gates the handful of admin actions reserved to a super admin — granting
 * or revoking admin/super-admin access, and payment refunds. Everything
 * else under /admin stays open to any admin (see EnsureUserIsAdmin). */
class EnsureUserIsSuperAdmin
{
    public function handle(Request $request, Closure $next): Response
    {
        abort_unless($request->user()?->isSuperAdmin(), 403, 'Super admin access required.');

        return $next($request);
    }
}
