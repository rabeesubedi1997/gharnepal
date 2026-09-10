<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\NeighborhoodProfileResource;
use App\Models\Neighborhood;
use App\Models\NeighborhoodScore;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class NeighborhoodScoreController extends Controller
{
    /** Upserts the overall score + every rated factor in one admin submission. */
    public function store(Request $request, Neighborhood $neighborhood): NeighborhoodProfileResource
    {
        $data = $request->validate([
            'factors' => ['required', 'array', 'min:1'],
            'factors.*.key' => ['required', Rule::in(NeighborhoodScore::FACTORS)],
            'factors.*.score' => ['required', 'integer', 'min:0', 'max:10'],
            'factors.*.notes' => ['nullable', 'string', 'max:255'],
        ]);

        $overall = (int) round(collect($data['factors'])->avg('score'));

        $score = $neighborhood->score()->updateOrCreate([], [
            'overall_score' => $overall,
            'source' => 'admin_curated',
            'computed_at' => now(),
        ]);

        // An admin submitting a real score is what "curated" means for a
        // neighborhood — flip it here rather than relying on a separate step.
        if (! $neighborhood->is_curated) {
            $neighborhood->update(['is_curated' => true]);
        }

        $score->factors()->delete();
        foreach ($data['factors'] as $factor) {
            $score->factors()->create([
                'factor_key' => $factor['key'],
                'score' => $factor['score'],
                'data_source' => 'admin',
                'notes' => $factor['notes'] ?? null,
            ]);
        }

        return new NeighborhoodProfileResource($neighborhood->load(['ward.municipality', 'score.factors']));
    }
}
