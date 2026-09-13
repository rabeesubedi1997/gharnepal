<?php

namespace App\Http\Controllers\Api\V1\Public;

use App\Http\Controllers\Controller;
use App\Http\Resources\PropertyListingSummaryResource;
use App\Models\FavoriteCollection;
use App\Models\PropertyListing;
use Illuminate\Http\JsonResponse;

class FavoriteCollectionController extends Controller
{
    /** Read-only, no auth: anyone holding the share link can view it. */
    public function show(string $token): JsonResponse
    {
        $collection = FavoriteCollection::where('share_token', $token)->with('user')->firstOrFail();

        $listings = PropertyListing::query()
            ->whereHas('favorites', fn ($q) => $q->where('favorite_collection_id', $collection->id))
            // Published only — a listing an owner has since paused, sold, or
            // withdrawn shouldn't linger as a live-looking card on someone
            // else's shared link.
            ->where('status', PropertyListing::STATUS_PUBLISHED)
            ->with(['property.address.municipality', 'property.address.ward', 'property.address.neighborhood', 'property.media'])
            ->latest()
            ->paginate(24);

        return (PropertyListingSummaryResource::collection($listings))
            ->additional([
                'collection' => [
                    'name' => $collection->name,
                    'curated_by' => $collection->user->name,
                ],
            ])
            ->response();
    }
}
