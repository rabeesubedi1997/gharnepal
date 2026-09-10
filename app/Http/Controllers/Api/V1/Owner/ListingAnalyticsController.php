<?php

namespace App\Http\Controllers\Api\V1\Owner;

use App\Http\Controllers\Controller;
use App\Models\PropertyListing;
use Illuminate\Http\JsonResponse;

class ListingAnalyticsController extends Controller
{
    public function show(PropertyListing $listing): JsonResponse
    {
        $this->authorize('update', $listing);

        return response()->json([
            'data' => [
                'views_count' => $listing->views_count,
                'favorites_count' => $listing->favorites()->count(),
                'inquiries_count' => \App\Models\Conversation::where('property_listing_id', $listing->id)->count(),
                'viewing_requests_count' => \App\Models\ViewingRequest::where('property_listing_id', $listing->id)->count(),
            ],
        ]);
    }
}
