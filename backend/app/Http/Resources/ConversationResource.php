<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ConversationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $user = $request->user();
        $other = $user ? $this->otherParticipant($user) : null;

        return [
            'id' => $this->id,
            'listing' => [
                'id' => $this->listing?->id,
                'slug' => $this->listing?->slug,
                'title' => $this->listing?->title,
                'cover_image_url' => $this->listing?->property?->media->first()?->url(),
            ],
            'other_participant' => $other ? ['id' => $other->id, 'name' => $other->name] : null,
            'status' => $this->status,
            'last_message_at' => $this->last_message_at,
            'unread_count' => $this->unread_messages_count ?? 0,
            'messages' => MessageResource::collection($this->whenLoaded('messages')),
        ];
    }
}
