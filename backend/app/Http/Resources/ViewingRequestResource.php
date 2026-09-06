<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ViewingRequestResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'listing' => [
                'id' => $this->listing?->id,
                'slug' => $this->listing?->slug,
                'title' => $this->listing?->title,
            ],
            'requester' => $this->requester ? ['id' => $this->requester->id, 'name' => $this->requester->name] : null,
            'host' => $this->host ? ['id' => $this->host->id, 'name' => $this->host->name] : null,
            'proposed_datetime' => $this->proposed_datetime,
            'confirmed_datetime' => $this->confirmed_datetime,
            'status' => $this->status,
            'notes' => $this->notes,
            'visit_verification' => $this->whenLoaded('visitVerification', fn () => $this->visitVerification ? [
                'visited' => $this->visitVerification->visited,
                'matched_listing' => $this->visitVerification->matched_listing,
                'price_accurate' => $this->visitVerification->price_accurate,
                'host_attended' => $this->visitVerification->host_attended,
                'documents_shown' => $this->visitVerification->documents_shown,
                'overall_comment' => $this->visitVerification->overall_comment,
            ] : null),
            'created_at' => $this->created_at,
        ];
    }
}
