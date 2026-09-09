<?php

use App\Http\Controllers\SitemapController;
use Illuminate\Support\Facades\Route;

// Root-level, not under /api/v1 — see SitemapController for why.
Route::get('/sitemap.xml', [SitemapController::class, 'index']);
Route::get('/robots.txt', [SitemapController::class, 'robots']);

// Single-domain hosting: the React SPA's build output is merged directly
// into public/ at deploy time (index.html + assets/), alongside Laravel's
// own public/index.php. Apache's default public/.htaccess only rewrites a
// request into Laravel at all when it doesn't already match a real file on
// disk (`RewriteCond %{REQUEST_FILENAME} !-f`) — so a request for an actual
// built asset (`/assets/index-abc123.js`) is served directly and never
// reaches this route file. What DOES reach here is every other real page
// (`/search`, `/listings/some-slug`, ...): serving the SPA's own
// index.html for all of them is what lets React Router's client-side
// routes work on a direct load or a refresh, not just via in-app
// navigation. Symfony's route compiler always prefers a literal route
// (this file's own /sitemap.xml/robots.txt, or anything in api.php) over
// this wildcard regardless of declaration order, so it's safe to
// register unconditionally last.
//
// Falls back to the default welcome view when public/index.html isn't
// there — local dev and CI never merge the SPA build into this Laravel
// checkout (the frontend runs on its own dev server instead), so this
// keeps `GET /` (and the stock ExampleTest asserting it's a 200) working
// exactly as before outside of an actual single-domain deployment.
Route::get('/{any?}', function () {
    $index = public_path('index.html');

    return file_exists($index) ? response()->file($index) : view('welcome');
})->where('any', '.*');
