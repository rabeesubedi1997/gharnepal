<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MatchPreferenceResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'purpose' => $this->purpose,
            'property_type' => $this->property_type,
            'budget_min' => $this->budget_min !== null ? (float) $this->budget_min : null,
            'budget_max' => $this->budget_max !== null ? (float) $this->budget_max : null,
            'min_bedrooms' => $this->min_bedrooms,
            'preferred_municipality_id' => $this->preferred_municipality_id,
            'preferred_municipality' => $this->whenLoaded('preferredMunicipality', fn () => $this->preferredMunicipality?->name),
            'work_lat' => $this->work_lat !== null ? (float) $this->work_lat : null,
            'work_lng' => $this->work_lng !== null ? (float) $this->work_lng : null,
            'work_location_label' => $this->work_location_label,
            'commute_limit_minutes' => $this->commute_limit_minutes,
            'family_size' => $this->family_size,
            'requires_school_nearby' => $this->requires_school_nearby,
            'requires_parking' => $this->requires_parking,
            'investment_purpose' => $this->investment_purpose,
            'lifestyle_tags' => $this->lifestyle_tags ?? [],
            'updated_at' => $this->updated_at,
        ];
    }
}
