<?php

namespace App\Http\Controllers\Api\V1\Public;

use App\Http\Controllers\Controller;
use App\Http\Resources\NeighborhoodProfileResource;
use App\Http\Resources\NeighborhoodSummaryResource;
use App\Models\Neighborhood;
use App\Models\Property;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class NeighborhoodController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        $neighborhoods = Neighborhood::query()
            ->with(['ward.municipality', 'score'])
            // Real published-listing count per neighborhood — backs the
            // homepage's "popular hotspots" pills, so those never drift
            // into invented copy like "Baluwatar (Embassy Hub)".
            ->withCount(['addresses as active_listings_count' => function ($q) {
                $q->whereHasMorph('addressable', [Property::class], function ($q2) {
                    $q2->whereHas('listings', fn ($q3) => $q3->where('status', 'published'));
                });
            }])
            ->orderBy('name')
            ->get();

        return NeighborhoodSummaryResource::collection($neighborhoods);
    }

    public function show(Neighborhood $neighborhood): NeighborhoodProfileResource
    {
        $neighborhood->load([
            'ward.municipality',
            'score.factors',
            'pois',
            'communityNotes' => fn ($q) => $q->where('status', 'approved')->latest(),
        ]);

        return new NeighborhoodProfileResource($neighborhood);
    }
}
