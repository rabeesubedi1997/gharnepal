<?php

namespace App\Http\Resources\Agency;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AgencyListingRowResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $property = $this->property;
        $address = $property?->address;
        $cover = $property?->media->first();

        return [
            'id' => $this->id,
            'slug' => $this->slug,
            'reference_code' => $this->referenceCode(),
            'title' => $this->title,
            'purpose' => $this->purpose,
            'price' => (float) $this->price,
            'price_period' => $this->price_period,
            'currency' => $this->currency,
            'property_type' => $property?->property_type,
            'area_sqm' => $property?->total_area_sqm,
            'cover_image_url' => $cover?->url(),
            'location' => $address ? [
                'municipality' => $address->municipality?->name,
                'ward_number' => $address->ward?->ward_number,
            ] : null,
            'published_at' => $this->published_at,
            // Real engagement signals for this listing — how many buyers
            // have messaged about it and how many site visits it has
            // generated — not a fabricated "engagement score".
            'inquiries_count' => (int) ($this->inquiries_count ?? 0),
            'leads_count' => (int) ($this->leads_count ?? 0),
        ];
    }
}
