<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class LandProfileResource extends JsonResource
{
    /**
     * Whether the *document itself* (a sensitive, PII-bearing upload) may be
     * shown to whoever is viewing this resource. Defaults true because every
     * existing caller except the public listing-detail endpoint is already
     * owner/admin-gated (LandProfileController's own `authorize()` calls);
     * PropertyResource explicitly sets this to false for unauthorized
     * viewers before rendering this resource on the public endpoint.
     */
    public bool $canViewDocument = true;

    public function toArray(Request $request): array
    {
        return [
            'kitta_number' => $this->kitta_number,
            'lalpurja_available' => $this->lalpurja_available,
            'lalpurja_document_url' => $this->canViewDocument ? $this->lalpurjaDocument?->url() : null,
            'road_access' => $this->road_access,
            'road_width_meters' => $this->road_width_meters,
            'road_type' => $this->road_type,
            'water_access' => $this->water_access,
            'electricity_access' => $this->electricity_access,
            'drainage_access' => $this->drainage_access,
            'land_classification' => $this->land_classification,
            'flood_risk' => $this->flood_risk,
            'landslide_risk' => $this->landslide_risk,
            'nearby_development_notes' => $this->nearby_development_notes,
            'document_verification_status' => $this->document_verification_status,
            'verified_at' => $this->verified_at,
            'completeness_percent' => $this->completenessPercent(),
        ];
    }
}
