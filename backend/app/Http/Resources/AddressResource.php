<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AddressResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'province' => $this->whenLoaded('province', fn () => ['id' => $this->province->id, 'name' => $this->province->name]),
            'district' => $this->whenLoaded('district', fn () => ['id' => $this->district->id, 'name' => $this->district->name]),
            'municipality' => $this->whenLoaded('municipality', fn () => ['id' => $this->municipality->id, 'name' => $this->municipality->name]),
            'ward' => $this->whenLoaded('ward', fn () => ['id' => $this->ward->id, 'ward_number' => $this->ward->ward_number]),
            'neighborhood' => $this->whenLoaded('neighborhood', fn () => $this->neighborhood ? ['id' => $this->neighborhood->id, 'name' => $this->neighborhood->name] : null),
            'street_address' => $this->street_address,
            'landmark' => $this->landmark,
            'lat' => $this->lat,
            'lng' => $this->lng,
        ];
    }
}
