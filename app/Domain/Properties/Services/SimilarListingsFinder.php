<?php

namespace App\Domain\Properties\Services;

use App\Models\PropertyListing;
use Illuminate\Database\Eloquent\Collection;

/**
 * Simple, transparent "similar nearby listings" — same ward, same type and
 * purpose, priced within 25% either way. No caching table (see plan's
 * similar_properties_cache) yet; at MVP scale this query is cheap enough to
 * run live, and a materialized cache can replace this body later without
 * touching callers.
 */
class SimilarListingsFinder
{
    private const PRICE_TOLERANCE = 0.25;
    private const LIMIT = 4;

    public function find(PropertyListing $listing): Collection
    {
        $property = $listing->property;
        $wardId = $property?->address?->ward_id;

        if (! $property || ! $wardId) {
            return new Collection();
        }

        $minPrice = (float) $listing->price * (1 - self::PRICE_TOLERANCE);
        $maxPrice = (float) $listing->price * (1 + self::PRICE_TOLERANCE);

        return PropertyListing::query()
            ->where('id', '!=', $listing->id)
            ->where('status', PropertyListing::STATUS_PUBLISHED)
            ->where('purpose', $listing->purpose)
            ->whereBetween('price', [$minPrice, $maxPrice])
            ->whereHas('property', function ($q) use ($property, $wardId) {
                $q->where('property_type', $property->property_type)
                    ->whereHas('address', fn ($a) => $a->where('ward_id', $wardId));
            })
            ->with(['property.address.municipality', 'property.address.ward', 'property.address.neighborhood', 'property.media', 'trustScore'])
            ->latest('published_at')
            ->limit(self::LIMIT)
            ->get();
    }
}
