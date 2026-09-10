<?php

namespace App\Http\Resources\Admin;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BlogPostResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'slug' => $this->slug,
            'excerpt' => $this->excerpt,
            'body' => $this->body,
            'cover_image_url' => $this->coverImageUrl(),
            'status' => $this->status,
            'author' => $this->whenLoaded('author', fn () => $this->author?->name),
            'published_at' => $this->published_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
