<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ListingReportResource extends JsonResource
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
            'reported_by' => $this->reportedBy ? ['id' => $this->reportedBy->id, 'name' => $this->reportedBy->name] : null,
            'reason' => $this->reason,
            'details' => $this->details,
            'status' => $this->status,
            'resolution_note' => $this->resolution_note,
            'created_at' => $this->created_at,
        ];
    }
}
