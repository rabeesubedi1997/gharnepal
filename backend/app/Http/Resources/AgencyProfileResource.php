<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class AgencyProfileResource extends JsonResource
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
            'verified_at' => $this->verified_at,
            'member_count' => $this->whenCounted('members'),
            'members' => $this->whenLoaded('members', fn () => $this->members->map(fn ($member) => [
                'name' => $member->name,
                'role_in_agency' => $member->pivot->role_in_agency,
            ])),
            'active_listings' => PropertyListingSummaryResource::collection(
                $this->when($this->resource->relationLoaded('activeListingsResults'), fn () => $this->resource->getRelation('activeListingsResults')),
            ),
        ];
    }
}
