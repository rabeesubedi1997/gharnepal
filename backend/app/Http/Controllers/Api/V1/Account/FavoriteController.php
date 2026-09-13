<?php

namespace App\Http\Controllers\Api\V1\Account;

use App\Http\Controllers\Controller;
use App\Http\Resources\PropertyListingSummaryResource;
use App\Models\Favorite;
use App\Models\PropertyListing;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class FavoriteController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate(['collection_id' => ['sometimes', 'integer']]);

        $listings = PropertyListing::query()
            ->whereHas('favorites', function ($q) use ($request) {
                $q->where('user_id', $request->user()->id);
                // No collection_id at all: everything the user has saved,
                // collected or not. collection_id=0 is the "All saved" tab's
                // explicit request for only the uncollected ones.
                if ($request->filled('collection_id')) {
                    $q->where('favorite_collection_id', (int) $request->input('collection_id') ?: null);
                }
            })
            ->with(['property.address.municipality', 'property.address.ward', 'property.address.neighborhood', 'property.media'])
            ->latest()
            ->paginate(12);

        return PropertyListingSummaryResource::collection($listings);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'listing_id' => ['required', 'integer', 'exists:property_listings,id'],
            'collection_id' => [
                'sometimes', 'nullable', 'integer',
                Rule::exists('favorite_collections', 'id')->where('user_id', $request->user()->id),
            ],
        ]);

        $favorite = Favorite::firstOrCreate([
            'user_id' => $request->user()->id,
            'property_listing_id' => $data['listing_id'],
        ], [
            'favorite_collection_id' => $data['collection_id'] ?? null,
        ]);

        return response()->json(['data' => ['favorited' => true]], $favorite->wasRecentlyCreated ? 201 : 200);
    }

    /** Moves an already-saved listing into (or out of, with collection_id: null) a collection. */
    public function move(Request $request, PropertyListing $listing): JsonResponse
    {
        $data = $request->validate([
            'collection_id' => [
                'nullable', 'integer',
                Rule::exists('favorite_collections', 'id')->where('user_id', $request->user()->id),
            ],
        ]);

        $favorite = Favorite::where('user_id', $request->user()->id)
            ->where('property_listing_id', $listing->id)
            ->firstOrFail();

        $favorite->update(['favorite_collection_id' => $data['collection_id'] ?? null]);

        return response()->json(['data' => ['favorited' => true]]);
    }

    public function destroy(Request $request, PropertyListing $listing): JsonResponse
    {
        Favorite::where('user_id', $request->user()->id)
            ->where('property_listing_id', $listing->id)
            ->delete();

        return response()->json(['data' => ['favorited' => false]]);
    }
}
