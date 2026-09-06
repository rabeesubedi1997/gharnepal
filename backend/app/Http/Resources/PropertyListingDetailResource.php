<?php

namespace App\Http\Resources;

use App\Domain\Seo\Services\SeoService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PropertyListingDetailResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $property = $this->property;
        $owner = $property?->owner ?? $property?->createdBy;

        return [
            'seo' => app(SeoService::class)->effectiveForListing($this->resource),
            'id' => $this->id,
            'slug' => $this->slug,
            'title' => $this->title,
            'description' => $this->description,
            'purpose' => $this->purpose,
            'price' => (float) $this->price,
            'price_period' => $this->price_period,
            'currency' => $this->currency,
            'negotiable' => $this->negotiable,
            'availability_date' => $this->availability_date,
            'status' => $this->status,
            'published_at' => $this->published_at,
            'views_count' => $this->views_count,
            'is_featured' => $this->isFeatured(),
            'featured_until' => $this->featured_until,
            'rating' => [
                'average' => $this->ratings_avg_score !== null ? round((float) $this->ratings_avg_score, 1) : null,
                'count' => (int) ($this->ratings_count ?? 0),
            ],
            'my_rating' => $request->user()
                ? $this->ratings()->where('user_id', $request->user()->id)->first()?->only(['id', 'score', 'comment'])
                : null,
            'property' => new PropertyResource($property),
            'amenities' => AmenityResource::collection($this->whenLoaded('amenities')),
            'poster' => $owner ? [
                'name' => $owner->name,
                'member_since' => $owner->created_at?->toDateString(),
                'agency' => $owner->relationLoaded('agencies')
                    ? $owner->agencies->whereNotNull('verified_at')->first(fn ($a) => $a->status === 'active')
                        ?->only(['name', 'slug'])
                    : null,
            ] : null,
            'trust' => $this->whenLoaded('trustScore', fn () => $this->trustScore ? new TrustScoreResource($this->trustScore) : null),
            'price_history' => $this->whenLoaded('priceHistory', fn () => $this->priceHistory->map(fn ($h) => [
                'price' => (float) $h->price,
                'changed_at' => $h->changed_at,
            ])),
            'similar_listings' => $this->when(
                $this->resource->relationLoaded('similarListingsResults'),
                fn () => PropertyListingSummaryResource::collection($this->resource->getRelation('similarListingsResults')),
            ),
        ];
    }
}
