<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\NeighborhoodPoiResource;
use App\Models\Neighborhood;
use App\Models\NeighborhoodPoi;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Validation\Rule;

class NeighborhoodPoiController extends Controller
{
    public function store(Request $request, Neighborhood $neighborhood): JsonResponse
    {
        $data = $request->validate([
            'poi_type' => ['required', Rule::in(['school', 'hospital', 'market', 'transport_stop', 'bank', 'other'])],
            'name' => ['required', 'string', 'max:255'],
            'lat' => ['nullable', 'numeric', 'between:-90,90'],
            'lng' => ['nullable', 'numeric', 'between:-180,180'],
        ]);

        $poi = $neighborhood->pois()->create([...$data, 'added_by' => $request->user()->id, 'verified' => true]);

        return (new NeighborhoodPoiResource($poi))->response()->setStatusCode(201);
    }

    public function destroy(NeighborhoodPoi $poi): Response
    {
        $poi->delete();

        return response()->noContent();
    }
}
