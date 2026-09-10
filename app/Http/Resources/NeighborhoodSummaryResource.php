<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Directory-listing shape — no `seo` (computing effective SEO per row would
 * mean one extra query per neighborhood on a page that never renders it);
 * that only matters on the single-profile page, see NeighborhoodProfileResource.
 */
class NeighborhoodSummaryResource extends JsonResource
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
        ];
    }
}
