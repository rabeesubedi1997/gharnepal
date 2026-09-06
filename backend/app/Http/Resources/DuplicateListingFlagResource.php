<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DuplicateListingFlagResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'listing' => [
                'id' => $this->listing?->id,
                'slug' => $this->listing?->slug,
                'title' => $this->listing?->title,
                'price' => (float) $this->listing?->price,
            ],
            'duplicate_of' => [
                'id' => $this->duplicateOf?->id,
                'slug' => $this->duplicateOf?->slug,
                'title' => $this->duplicateOf?->title,
                'price' => (float) $this->duplicateOf?->price,
            ],
            'match_score' => $this->match_score,
            'match_reasons' => $this->match_reasons,
            'status' => $this->status,
            'created_at' => $this->created_at,
        ];
    }
}
