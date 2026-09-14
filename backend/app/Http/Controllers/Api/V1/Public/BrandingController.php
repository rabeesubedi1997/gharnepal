<?php

namespace App\Http\Controllers\Api\V1\Public;

use App\Http\Controllers\Controller;
use App\Http\Resources\BrandingResource;
use App\Models\PlatformBranding;

/** Public, unauthenticated — the frontend fetches this once at boot to
 * apply the admin-configured site name/favicon live. */
class BrandingController extends Controller
{
    public function show(): BrandingResource
    {
        return new BrandingResource(PlatformBranding::current());
    }
}
