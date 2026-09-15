<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** What the checkout screen sees — never credentials, only what's chosen for it. */
class PublicPaymentGatewayResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'provider' => $this->provider,
            'label' => $this->label,
            'is_sandbox' => $this->is_sandbox,
        ];
    }
}
