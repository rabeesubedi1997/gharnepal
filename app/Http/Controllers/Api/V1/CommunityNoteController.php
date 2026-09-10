<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\CommunityNoteResource;
use App\Models\CommunityNote;
use App\Models\Neighborhood;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class CommunityNoteController extends Controller
{
    public function store(Request $request, Neighborhood $neighborhood): JsonResponse
    {
        $user = $request->user();

        // Matches the product spec: only verified users contribute neighborhood
        // facts — phone verification is enough of a bar to deter throwaway spam.
        if (! $user->phone_verified_at) {
            throw ValidationException::withMessages([
                'phone' => 'Verify your phone number before contributing neighborhood notes.',
            ]);
        }

        $data = $request->validate([
            'category' => ['required', Rule::in([
                'water_supply', 'power_interruption', 'road_condition', 'isp_quality',
                'parking_difficulty', 'seasonal_flooding', 'noise', 'market_access', 'other',
            ])],
            'body' => ['required', 'string', 'max:500'],
        ]);

        $note = CommunityNote::create([
            'neighborhood_id' => $neighborhood->id,
            'submitted_by' => $user->id,
            'category' => $data['category'],
            'body' => $data['body'],
            'status' => 'pending',
        ]);

        return (new CommunityNoteResource($note))->response()->setStatusCode(201);
    }
}
