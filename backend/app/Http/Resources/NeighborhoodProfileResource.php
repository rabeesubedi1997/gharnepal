<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class NeighborhoodProfileResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $score = $this->whenLoaded('score');

        return [
            'id' => $this->id,
            'name' => $this->name,
            'name_ne' => $this->name_ne,
            'is_curated' => $this->is_curated,
            'ward' => $this->whenLoaded('ward', fn () => [
                'id' => $this->ward->id,
                'ward_number' => $this->ward->ward_number,
                'municipality' => $this->ward->municipality?->name,
            ]),
            'score' => $score ? [
                'overall_score' => $score->overall_score,
                'source' => $score->source,
                'computed_at' => $score->computed_at,
                'factors' => $score->relationLoaded('factors') ? $score->factors->map(fn ($f) => [
                    'key' => $f->factor_key,
                    'score' => $f->score,
                    'notes' => $f->notes,
                ]) : [],
            ] : null,
            'pois' => NeighborhoodPoiResource::collection($this->whenLoaded('pois')),
            'community_notes' => CommunityNoteResource::collection($this->whenLoaded('communityNotes')),
        ];
    }
}
