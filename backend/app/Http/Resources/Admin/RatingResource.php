<?php

namespace App\Http\Resources\Admin;

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
            'status' => $this->status,
            'user' => $this->whenLoaded('user', fn () => $this->user ? ['id' => $this->user->id, 'name' => $this->user->name] : null),
            'listing' => $this->whenLoaded('rateable', fn () => $this->rateable ? [
                'id' => $this->rateable->id,
                'slug' => $this->rateable->slug,
                'title' => $this->rateable->title,
            ] : null),
            'created_at' => $this->created_at,
        ];
    }
}
