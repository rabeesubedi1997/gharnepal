<?php

namespace App\Http\Resources\Admin;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'status' => $this->status,
            'email_verified' => $this->email_verified_at !== null,
            'phone_verified' => $this->phone_verified_at !== null,
            'roles' => $this->whenLoaded('roles', fn () => $this->roles->pluck('key')),
            'agencies' => $this->whenLoaded('agencies', fn () => $this->agencies->pluck('name')),
            'created_at' => $this->created_at,
        ];
    }
}
