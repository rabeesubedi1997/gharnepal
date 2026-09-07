<?php

namespace App\Http\Resources;

use App\Models\Role;
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
            // An admin can step into a thread (e.g. to answer a question or
            // mediate a dispute) — flag it so the UI never presents that as
            // coming from the other buyer/owner party.
            'is_from_support' => $this->sender?->hasRole(Role::ADMIN) ?? false,
            'read_at' => $this->read_at,
            'created_at' => $this->created_at,
        ];
    }
}
