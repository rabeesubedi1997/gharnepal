<?php

namespace App\Domain\Properties\Services;

use App\Models\DuplicateListingFlag;
use App\Models\PropertyListing;

/**
 * Heuristic, admin-assisted duplicate detection — never auto-rejects, only
 * raises a flag for a human to confirm or dismiss in the moderation queue
 * (see plan risk: false positive/negative tradeoff on fuzzy matching).
 */
class DuplicateListingDetector
{
    private const SCORE_THRESHOLD = 50;
    private const PRICE_TOLERANCE = 0.10; // 10%
    private const AREA_TOLERANCE = 0.10;

    public function scan(PropertyListing $listing): void
    {
        $property = $listing->property;
        $address = $property?->address;

        if (! $property || ! $address) {
            return;
        }

        $candidates = PropertyListing::query()
            ->where('id', '!=', $listing->id)
            ->whereIn('status', [PropertyListing::STATUS_PUBLISHED, PropertyListing::STATUS_PENDING_REVIEW])
            ->whereHas('property', function ($q) use ($property, $address) {
                $q->where('property_type', $property->property_type)
                    ->whereHas('address', fn ($a) => $a->where('ward_id', $address->ward_id));
            })
            ->with('property')
            ->get();

        foreach ($candidates as $candidate) {
            [$score, $reasons] = $this->score($listing, $candidate);

            if ($score >= self::SCORE_THRESHOLD) {
                DuplicateListingFlag::firstOrCreate(
                    ['property_listing_id' => $listing->id, 'duplicate_of_listing_id' => $candidate->id],
                    ['match_score' => $score, 'match_reasons' => $reasons, 'status' => 'unreviewed'],
                );
            }
        }
    }

    /** @return array{0: int, 1: string[]} */
    private function score(PropertyListing $a, PropertyListing $b): array
    {
        $score = 0;
        $reasons = [];

        $ownerA = $a->property?->owner_user_id;
        $ownerB = $b->property?->owner_user_id;
        if ($ownerA && $ownerA === $ownerB) {
            $score += 40;
            $reasons[] = 'same_owner';
        }

        if ($this->withinTolerance((float) $a->price, (float) $b->price, self::PRICE_TOLERANCE)) {
            $score += 20;
            $reasons[] = 'similar_price';
        }

        $areaA = (float) ($a->property?->total_area_sqm ?? 0);
        $areaB = (float) ($b->property?->total_area_sqm ?? 0);
        if ($areaA > 0 && $areaB > 0 && $this->withinTolerance($areaA, $areaB, self::AREA_TOLERANCE)) {
            $score += 20;
            $reasons[] = 'similar_area';
        }

        similar_text(mb_strtolower($a->title), mb_strtolower($b->title), $titleSimilarity);
        if ($titleSimilarity >= 60) {
            $score += 20;
            $reasons[] = 'similar_title';
        }

        $reasons[] = 'same_ward';

        return [$score, $reasons];
    }

    private function withinTolerance(float $a, float $b, float $tolerance): bool
    {
        if ($a <= 0 || $b <= 0) {
            return false;
        }

        return abs($a - $b) / max($a, $b) <= $tolerance;
    }
}
