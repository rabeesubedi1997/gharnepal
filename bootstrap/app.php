<?php

use App\Http\Middleware\EnsureAccountIsActive;
use App\Http\Middleware\EnsureUserIsAdmin;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->statefulApi();
        // Applies throttle:api (the 'api' limiter defined in AppServiceProvider)
        // to every route in the api middleware group — previously nothing
        // rate-limited the API at all. Login/register/OTP get their own,
        // tighter limiters applied directly on those routes in routes/api.php.
        $middleware->throttleApi();
        $middleware->alias(['admin' => EnsureUserIsAdmin::class]);
        // Global (not just the `api` group) so it also covers the stateful
        // web routes Sanctum's SPA auth uses — a no-op for guests either way.
        $middleware->append(EnsureAccountIsActive::class);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        //
    })->create();
