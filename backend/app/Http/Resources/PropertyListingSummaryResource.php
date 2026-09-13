<?php

namespace App\Http\Resources;

use App\Domain\Calculators\Services\AreaUnitConverter;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PropertyListingSummaryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $property = $this->property;
        $address = $property?->address;
        $cover = $property?->media->first();
        $areaSqm = $property?->total_area_sqm;

        return [
            'id' => $this->id,
            'slug' => $this->slug,
            'reference_code' => $this->referenceCode(),
            'title' => $this->title,
            'purpose' => $this->purpose,
            'price' => (float) $this->price,
            'price_period' => $this->price_period,
            'currency' => $this->currency,
            'negotiable' => $this->negotiable,
            'status' => $this->status,
            'property_type' => $property?->property_type,
            'bedrooms' => $property?->bedrooms,
            'bathrooms' => $property?->bathrooms,
            'area_sqm' => $areaSqm,
            // Same real conversion used on the listing-detail page — lets
            // card display honor the site-wide Aana/Ropani vs. Sq.Ft
            // preference instead of always showing square meters, which
            // nobody in this market actually thinks in.
            'area_display' => $areaSqm !== null ? [
                'sqft' => AreaUnitConverter::fromSqm((float) $areaSqm, 'sqft'),
                'aana' => AreaUnitConverter::fromSqm((float) $areaSqm, 'aana'),
                'ropani' => AreaUnitConverter::fromSqm((float) $areaSqm, 'ropani'),
            ] : null,
            'cover_image_url' => $cover?->url(),
            'location' => $address ? [
                'municipality' => $address->municipality?->name,
                'ward_number' => $address->ward?->ward_number,
                'neighborhood' => $address->neighborhood?->name,
                'lat' => $address->lat,
                'lng' => $address->lng,
            ] : null,
            'published_at' => $this->published_at,
            'views_count' => $this->views_count,
            'trust_score' => $this->whenLoaded('trustScore', fn () => $this->trustScore?->total_score),
            'is_featured' => $this->isFeatured(),
            'rating' => [
                'average' => $this->ratings_avg_score !== null ? round((float) $this->ratings_avg_score, 1) : null,
                'count' => (int) ($this->ratings_count ?? 0),
            ],
        ];
    }
}
