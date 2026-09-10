<?php

namespace App\Http\Controllers\Api\V1\Public;

use App\Domain\Marketing\AdvertisementPlacement;
use App\Http\Controllers\Controller;
use App\Http\Resources\AdvertisementResource;
use App\Models\Advertisement;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class AdvertisementController extends Controller
{
    /** Every ad slot is explicit about where it renders — there is no "give me
     * every active ad" endpoint, so a page can never accidentally show an ad
     * meant for a different slot. */
    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate([
            'placement' => ['required', Rule::in(AdvertisementPlacement::keys())],
        ]);

        $ads = Advertisement::query()
            ->where('placement', $request->string('placement'))
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->get();

        return AdvertisementResource::collection($ads);
    }
}
