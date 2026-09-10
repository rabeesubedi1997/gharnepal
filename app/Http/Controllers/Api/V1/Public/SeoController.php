<?php

namespace App\Http\Controllers\Api\V1\Public;

use App\Domain\Seo\Services\SeoService;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;

/** Effective (override-merged) SEO metadata for the site's static/category pages. */
class SeoController extends Controller
{
    public function __construct(private readonly SeoService $seo) {}

    public function page(string $key): JsonResponse
    {
        $effective = $this->seo->effectiveForStaticPage($key);
        abort_unless($effective, 404, 'Unknown page.');

        return response()->json(['data' => $effective]);
    }
}
