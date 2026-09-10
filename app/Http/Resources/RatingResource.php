<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RatingResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'score' => $this->score,
            'comment' => $this->comment,
            'user' => $this->whenLoaded('user', fn () => $this->user ? ['name' => $this->user->name] : null),
            'created_at' => $this->created_at,
        ];
    }
}
