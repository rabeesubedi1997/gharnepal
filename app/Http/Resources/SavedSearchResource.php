<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SavedSearchResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'filters' => $this->filters,
            'alert_frequency' => $this->alert_frequency,
            'last_notified_at' => $this->last_notified_at,
            'created_at' => $this->created_at,
        ];
    }
}
