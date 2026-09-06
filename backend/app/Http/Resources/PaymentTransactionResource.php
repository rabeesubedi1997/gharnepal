<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PaymentTransactionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'plan_key' => $this->plan_key,
            'plan_days' => $this->plan_days,
            'amount' => (float) $this->amount,
            'currency' => $this->currency,
            'gateway' => $this->gateway,
            'gateway_reference' => $this->gateway_reference,
            'status' => $this->status,
            'completed_at' => $this->completed_at,
            'created_at' => $this->created_at,
            'listing' => $this->whenLoaded('propertyListing', fn () => $this->propertyListing ? [
                'id' => $this->propertyListing->id,
                'slug' => $this->propertyListing->slug,
                'title' => $this->propertyListing->title,
                'featured_until' => $this->propertyListing->featured_until,
            ] : null),
            'user' => $this->whenLoaded('user', fn () => $this->user ? [
                'id' => $this->user->id,
                'name' => $this->user->name,
            ] : null),
        ];
    }
}
