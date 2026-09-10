<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Domain\Trust\Services\TrustScoreCalculator;
use App\Http\Controllers\Controller;
use App\Http\Resources\TrustScoreResource;
use App\Models\PropertyListing;
use App\Models\TrustScoreOverride;
use Illuminate\Http\Request;

class TrustOverrideController extends Controller
{
    public function __construct(private readonly TrustScoreCalculator $trustScoreCalculator) {}

    public function store(Request $request, PropertyListing $listing): TrustScoreResource
    {
        $data = $request->validate([
            'override_score' => ['required', 'integer', 'min:0', 'max:100'],
            'note' => ['required', 'string', 'max:1000'],
        ]);

        // Only one active override per listing — deactivate any prior one first.
        TrustScoreOverride::where('property_listing_id', $listing->id)->update(['active' => false]);

        TrustScoreOverride::create([
            'property_listing_id' => $listing->id,
            'admin_user_id' => $request->user()->id,
            'override_score' => $data['override_score'],
            'note' => $data['note'],
            'active' => true,
        ]);

        $score = $this->trustScoreCalculator->recompute($listing);

        return new TrustScoreResource($score);
    }

    public function destroy(Request $request, PropertyListing $listing): TrustScoreResource
    {
        TrustScoreOverride::where('property_listing_id', $listing->id)->where('active', true)->update(['active' => false]);

        $score = $this->trustScoreCalculator->recompute($listing);

        return new TrustScoreResource($score);
    }
}
