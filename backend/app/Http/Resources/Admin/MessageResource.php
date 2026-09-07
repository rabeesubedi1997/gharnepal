<?php

namespace App\Http\Resources\Admin;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MessageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'body' => $this->body,
            'sender' => $this->whenLoaded('sender', fn () => $this->sender ? ['id' => $this->sender->id, 'name' => $this->sender->name] : null),
            'read_at' => $this->read_at,
            'created_at' => $this->created_at,
        ];
    }
}
