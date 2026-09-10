<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CommunityNoteResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'neighborhood_id' => $this->neighborhood_id,
            'category' => $this->category,
            'body' => $this->body,
            'status' => $this->status,
            'rejection_reason' => $this->rejection_reason,
            'submitted_by' => $this->whenLoaded('submittedBy', fn () => $this->submittedBy ? ['name' => $this->submittedBy->name] : null),
            'neighborhood' => $this->whenLoaded('neighborhood', fn () => ['id' => $this->neighborhood->id, 'name' => $this->neighborhood->name]),
            'created_at' => $this->created_at,
        ];
    }
}
