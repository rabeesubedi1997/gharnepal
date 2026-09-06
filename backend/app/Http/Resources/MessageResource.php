<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MessageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'conversation_id' => $this->conversation_id,
            'body' => $this->body,
            'sender_id' => $this->sender_user_id,
            'is_mine' => $this->sender_user_id === $request->user()?->id,
            'read_at' => $this->read_at,
            'created_at' => $this->created_at,
        ];
    }
}
