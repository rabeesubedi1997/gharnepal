<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin \App\Models\PlatformBranding */
class BrandingResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'site_name' => $this->site_name,
            'favicon_url' => $this->faviconUrl(),
            'app_icon_url' => $this->appIconUrl(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
