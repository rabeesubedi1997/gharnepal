<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CostCalculatorScenarioResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'type' => $this->type,
            'name' => $this->name,
            'inputs' => $this->inputs,
            'result' => $this->computed_result,
            'listing_id' => $this->property_listing_id,
            'created_at' => $this->created_at,
        ];
    }
}
