<?php

namespace App\Http\Controllers\Api\V1\Account;

use App\Http\Controllers\Controller;
use App\Http\Resources\PropertyListingSummaryResource;
use App\Models\Favorite;
use App\Models\PropertyListing;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class FavoriteController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $listings = PropertyListing::query()
            ->whereHas('favorites', fn ($q) => $q->where('user_id', $request->user()->id))
            ->with(['property.address.municipality', 'property.address.ward', 'property.address.neighborhood', 'property.media'])
            ->latest()
            ->paginate(12);

        return PropertyListingSummaryResource::collection($listings);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate(['listing_id' => ['required', 'integer', 'exists:property_listings,id']]);

        $favorite = Favorite::firstOrCreate([
            'user_id' => $request->user()->id,
            'property_listing_id' => $data['listing_id'],
        ]);

        return response()->json(['data' => ['favorited' => true]], $favorite->wasRecentlyCreated ? 201 : 200);
    }

    public function destroy(Request $request, PropertyListing $listing): JsonResponse
    {
        Favorite::where('user_id', $request->user()->id)
            ->where('property_listing_id', $listing->id)
            ->delete();

        return response()->json(['data' => ['favorited' => false]]);
    }
}
