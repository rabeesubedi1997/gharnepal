<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class FavoriteCollectionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'share_token' => $this->share_token,
            'listings_count' => $this->whenCounted('favorites'),
            'created_at' => $this->created_at,
        ];
    }
}
