<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class AgencyResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'slug' => $this->slug,
            'logo_url' => $this->logo_path ? Storage::disk('public')->url($this->logo_path) : null,
            'description' => $this->description,
            'is_verified' => $this->isVerified(),
            'member_count' => $this->whenCounted('members'),
            'active_listings_count' => $this->active_listings_count ?? 0,
        ];
    }
}
