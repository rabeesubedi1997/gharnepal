<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MessageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $conversation = $this->conversation;

        return [
            'id' => $this->id,
            'conversation_id' => $this->conversation_id,
            'body' => $this->body,
            'sender_id' => $this->sender_user_id,
            'is_mine' => $this->sender_user_id === $request->user()?->id,
            // Whether the sender is neither of this conversation's two real
            // participants — i.e. an admin who stepped in from outside, not
            // one of the buyer/owner just happening to also hold the admin
            // role. Checking the sender's role directly was wrong: it mislabeled
            // an admin's own genuine buyer/owner messages (sent through their
            // own account, participating normally) as "support".
            'is_from_support' => $conversation
                && $this->sender_user_id !== $conversation->buyer_user_id
                && $this->sender_user_id !== $conversation->owner_user_id,
            'read_at' => $this->read_at,
            'created_at' => $this->created_at,
        ];
    }
}
