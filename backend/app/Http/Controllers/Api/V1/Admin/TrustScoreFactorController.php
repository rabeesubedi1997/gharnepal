<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\TrustScoreFactorResource;
use App\Models\TrustScoreFactor;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

/**
 * The 9 trust-score factors are a fixed catalog the calculator's `evaluate()`
 * switch knows how to compute (see TrustScoreCalculator) — admins can tune
 * whether a factor counts and how many points it's worth, but never
 * add/remove a factor, since an unknown key would just silently score zero.
 */
class TrustScoreFactorController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        return TrustScoreFactorResource::collection(TrustScoreFactor::orderBy('id')->get());
    }

    public function update(Request $request, TrustScoreFactor $trustScoreFactor): TrustScoreFactorResource
    {
        $data = $request->validate([
            'is_active' => ['sometimes', 'boolean'],
            'max_points' => ['sometimes', 'integer', 'min:1', 'max:100'],
        ]);

        $trustScoreFactor->update($data);

        return new TrustScoreFactorResource($trustScoreFactor);
    }
}
