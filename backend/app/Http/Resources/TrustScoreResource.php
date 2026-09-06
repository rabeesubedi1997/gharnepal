<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TrustScoreResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'score' => $this->total_score,
            'computed_score' => $this->computed_score,
            'is_overridden' => $this->total_score !== $this->computed_score,
            'computed_at' => $this->computed_at,
            'breakdown' => $this->whenLoaded('breakdowns', fn () => $this->breakdowns->map(fn ($b) => [
                'key' => $b->factor?->key,
                'label' => $b->factor?->label,
                'description' => $b->factor?->description,
                'points_awarded' => $b->points_awarded,
                'max_points' => $b->max_points,
                'explanation' => $b->explanation,
            ])),
        ];
    }
}
