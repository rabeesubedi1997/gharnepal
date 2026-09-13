<?php

namespace App\Http\Resources;

use App\Domain\Calculators\Services\AreaUnitConverter;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Auth;

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
            'facing_direction' => $this->facing_direction,
            'water_tank_capacity_liters' => $this->water_tank_capacity_liters,
            'structural_notes' => $this->structural_notes,
            'floor_breakdown' => $this->whenLoaded('floorBreakdown', fn () => $this->floorBreakdown->map(fn ($floor) => [
                'id' => $floor->id,
                'label' => $floor->label,
                'area_sqm' => $floor->area_sqm,
                'display' => $floor->area_sqm !== null ? [
                    'sqft' => AreaUnitConverter::fromSqm((float) $floor->area_sqm, 'sqft'),
                ] : null,
                'description' => $floor->description,
            ])),
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
                fn () => $this->whenLoaded('landProfile', function () {
                    if (! $this->landProfile) {
                        return null;
                    }

                    $resource = new LandProfileResource($this->landProfile);

                    // The land-title document itself is sensitive (a real
                    // ownership document) — only the property's own
                    // owner/creator or an admin may see the file, never a
                    // guest or an unrelated logged-in buyer browsing the
                    // public listing endpoint. Every other land_profile field
                    // (kitta number, road/water/electricity access, risk
                    // notes, etc.) stays visible to anyone — it's ordinary
                    // buyer-facing property information, not PII.
                    //
                    // Auth::guard('sanctum')->user(), not $request->user():
                    // this listing endpoint carries no `auth:sanctum`
                    // middleware (it's public), so the default 'web' guard
                    // never picks up a bearer-token mobile client — asking
                    // the sanctum guard directly checks both the SPA's
                    // session and a bearer token, same convention already
                    // used by EnsureAccountIsActive.
                    $user = Auth::guard('sanctum')->user();
                    $resource->canViewDocument = (bool) $user && (
                        $user->id === $this->owner_user_id
                        || $user->id === $this->created_by
                        || $user->isAdmin()
                    );

                    return $resource;
                }),
            ),
        ];
    }
}
