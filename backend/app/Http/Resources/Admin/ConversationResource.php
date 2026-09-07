<?php

namespace App\Http\Resources\Admin;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ConversationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $lastMessage = $this->whenLoaded('messages', fn () => $this->messages->last());

        return [
            'id' => $this->id,
            'status' => $this->status,
            'listing' => $this->property_listing_id ? [
                'id' => $this->listing?->id,
                'slug' => $this->listing?->slug,
                'title' => $this->listing?->title,
            ] : null,
            'property_request' => $this->property_request_id ? [
                'id' => $this->propertyRequest?->id,
                'purpose' => $this->propertyRequest?->purpose,
                'property_type' => $this->propertyRequest?->property_type,
            ] : null,
            'buyer' => $this->buyer ? ['id' => $this->buyer->id, 'name' => $this->buyer->name, 'email' => $this->buyer->email] : null,
            'owner' => $this->owner ? ['id' => $this->owner->id, 'name' => $this->owner->name, 'email' => $this->owner->email] : null,
            'messages_count' => $this->messages_count ?? null,
            'last_message_at' => $this->last_message_at,
            'last_message_preview' => $lastMessage instanceof \App\Models\Message ? \Illuminate\Support\Str::limit($lastMessage->body, 120) : null,
            'messages' => MessageResource::collection($this->whenLoaded('messages')),
        ];
    }
}
