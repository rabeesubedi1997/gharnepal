<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class WardResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'municipality_id' => $this->municipality_id,
            'ward_number' => $this->ward_number,
            'name' => $this->name,
            'centroid_lat' => $this->centroid_lat,
            'centroid_lng' => $this->centroid_lng,
        ];
    }
}
