<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BannerResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'subtitle' => $this->subtitle,
            'image_url' => $this->imageUrl(),
            'link_url' => $this->link_url,
            'cta_label' => $this->cta_label,
            'sort_order' => $this->sort_order,
            'is_active' => $this->is_active,
        ];
    }
}
