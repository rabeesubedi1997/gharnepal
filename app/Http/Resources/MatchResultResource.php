<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MatchResultResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'score' => $this->score,
            'reasons' => $this->reasons,
            'computed_at' => $this->computed_at,
            'listing' => new PropertyListingSummaryResource($this->whenLoaded('propertyListing')),
        ];
    }
}
