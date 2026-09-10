<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class NeighborhoodPoiResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'poi_type' => $this->poi_type,
            'name' => $this->name,
            'lat' => $this->lat,
            'lng' => $this->lng,
        ];
    }
}
