<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MunicipalityResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'district_id' => $this->district_id,
            'name' => $this->name,
            'name_ne' => $this->name_ne,
            'type' => $this->type,
            'code' => $this->code,
            'ward_count' => $this->ward_count,
        ];
    }
}
