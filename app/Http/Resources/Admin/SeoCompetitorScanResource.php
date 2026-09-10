<?php

namespace App\Http\Resources\Admin;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SeoCompetitorScanResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'page_key' => $this->page_key,
            'competitor_url' => $this->competitor_url,
            'scanned_title' => $this->scanned_title,
            'scanned_meta_description' => $this->scanned_meta_description,
            'scanned_meta_keywords' => $this->scanned_meta_keywords,
            'scanned_headings' => $this->scanned_headings ?? [],
            'scanned_keywords' => $this->scanned_keywords ?? [],
            'scanned_og_image' => $this->scanned_og_image,
            'word_count' => $this->word_count,
            'scanned_by' => $this->whenLoaded('scannedBy', fn () => $this->scannedBy?->name),
            'created_at' => $this->created_at,
        ];
    }
}
