<?php

namespace App\Http\Resources;

use App\Domain\Calculators\Services\AreaUnitConverter;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PropertyResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'property_type' => $this->property_type,
            'area' => [
                'sqm' => $this->total_area_sqm,
                'entered_value' => $this->total_area_value_entered,
                'entered_unit' => $this->total_area_unit_entered,
                'display' => $this->total_area_sqm !== null ? [
                    'sqft' => AreaUnitConverter::fromSqm((float) $this->total_area_sqm, 'sqft'),
                    'aana' => AreaUnitConverter::fromSqm((float) $this->total_area_sqm, 'aana'),
                    'ropani' => AreaUnitConverter::fromSqm((float) $this->total_area_sqm, 'ropani'),
                    'kattha' => AreaUnitConverter::fromSqm((float) $this->total_area_sqm, 'kattha'),
                    'dhur' => AreaUnitConverter::fromSqm((float) $this->total_area_sqm, 'dhur'),
                ] : null,
            ],
            'bedrooms' => $this->bedrooms,
            'bathrooms' => $this->bathrooms,
            'floors' => $this->floors,
            'year_built' => $this->year_built,
            'parking_spaces' => $this->parking_spaces,
            'parking_type' => $this->parking_type,
            'is_furnished' => $this->is_furnished,
            'address' => new AddressResource($this->whenLoaded('address')),
            'media' => MediaResource::collection($this->whenLoaded('media')),
            'listings' => $this->whenLoaded('listings', fn () => $this->listings->map(fn ($listing) => [
                'id' => $listing->id,
                'slug' => $listing->slug,
                'title' => $listing->title,
                'status' => $listing->status,
                'purpose' => $listing->purpose,
                'price' => (float) $listing->price,
                'is_featured' => $listing->isFeatured(),
                'featured_until' => $listing->featured_until,
            ])),
            'land_profile' => $this->when(
                $this->property_type === 'land',
                fn () => $this->whenLoaded('landProfile', fn () => $this->landProfile ? new LandProfileResource($this->landProfile) : null),
            ),
        ];
    }
}
