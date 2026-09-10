<?php

namespace App\Http\Controllers\Api\V1\Public;

use App\Http\Controllers\Controller;
use App\Http\Resources\NeighborhoodProfileResource;
use App\Http\Resources\NeighborhoodSummaryResource;
use App\Models\Neighborhood;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class NeighborhoodController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        $neighborhoods = Neighborhood::query()
            ->with(['ward.municipality', 'score'])
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
