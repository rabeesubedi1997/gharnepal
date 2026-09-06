<?php

namespace App\Http\Resources\Admin;

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
            'registration_number' => $this->registration_number,
            'status' => $this->status,
            'is_verified' => $this->isVerified(),
            'verified_at' => $this->verified_at,
            'member_count' => $this->whenCounted('members'),
            'created_at' => $this->created_at,
        ];
    }
}
