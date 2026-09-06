<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PropertyRequestResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'purpose' => $this->purpose,
            'property_type' => $this->property_type,
            'budget_min' => $this->budget_min !== null ? (int) $this->budget_min : null,
            'budget_max' => $this->budget_max !== null ? (int) $this->budget_max : null,
            'bedrooms_min' => $this->bedrooms_min,
            'municipality' => $this->whenLoaded('municipality', fn () => $this->municipality?->name),
            'notes' => $this->notes,
            'status' => $this->status,
            'posted_by' => $this->whenLoaded('user', fn () => $this->user?->name),
            'is_mine' => $request->user()?->id === $this->user_id,
            'created_at' => $this->created_at,
        ];
    }
}
