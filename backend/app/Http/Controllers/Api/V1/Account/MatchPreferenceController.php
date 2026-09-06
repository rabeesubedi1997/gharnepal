<?php

namespace App\Http\Controllers\Api\V1\Account;

use App\Domain\Matching\Services\MatchScorer;
use App\Http\Controllers\Controller;
use App\Http\Resources\MatchPreferenceResource;
use App\Models\MatchPreference;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class MatchPreferenceController extends Controller
{
    public function __construct(private readonly MatchScorer $matchScorer) {}

    public function show(Request $request): MatchPreferenceResource
    {
        $preference = $request->user()->matchPreference()->with('preferredMunicipality')->first()
            ?? new MatchPreference(['lifestyle_tags' => []]);

        return new MatchPreferenceResource($preference);
    }

    public function store(Request $request): MatchPreferenceResource
    {
        $data = $request->validate([
            'purpose' => ['nullable', Rule::in(['sale', 'rent'])],
            'property_type' => ['nullable', Rule::in(['room', 'apartment', 'house', 'land', 'commercial'])],
            'budget_min' => ['nullable', 'numeric', 'min:0'],
            'budget_max' => ['nullable', 'numeric', 'min:0'],
            'min_bedrooms' => ['nullable', 'integer', 'min:0', 'max:20'],
            'preferred_municipality_id' => ['nullable', 'integer', 'exists:municipalities,id'],
            'work_lat' => ['nullable', 'numeric', 'between:-90,90'],
            'work_lng' => ['nullable', 'numeric', 'between:-180,180'],
            'work_location_label' => ['nullable', 'string', 'max:255'],
            'commute_limit_minutes' => ['nullable', 'integer', 'min:5', 'max:180'],
            'family_size' => ['nullable', 'integer', 'min:1', 'max:20'],
            'requires_school_nearby' => ['nullable', 'boolean'],
            'requires_parking' => ['nullable', 'boolean'],
            'investment_purpose' => ['nullable', 'boolean'],
            'lifestyle_tags' => ['nullable', 'array', 'max:7'],
            'lifestyle_tags.*' => [Rule::in(MatchPreference::LIFESTYLE_TAGS)],
        ]);

        if (isset($data['budget_min'], $data['budget_max']) && $data['budget_max'] < $data['budget_min']) {
            throw ValidationException::withMessages([
                'budget_max' => 'Maximum budget must be greater than or equal to the minimum budget.',
            ]);
        }

        // The global TrimStrings/ConvertEmptyStringsToNull middleware pair
        // trims a literal `false` down to "" and then nulls it out before it
        // reaches here — coerce these NOT NULL boolean columns explicitly
        // rather than trusting whatever survived validation.
        $data['requires_school_nearby'] = $request->boolean('requires_school_nearby');
        $data['requires_parking'] = $request->boolean('requires_parking');
        $data['investment_purpose'] = $request->boolean('investment_purpose');

        $preference = $request->user()->matchPreference()->updateOrCreate([], $data);

        $this->matchScorer->recompute($preference);

        return new MatchPreferenceResource($preference->load('preferredMunicipality'));
    }
}
