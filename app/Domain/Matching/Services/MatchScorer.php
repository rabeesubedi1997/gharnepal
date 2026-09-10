<?php

namespace App\Domain\Matching\Services;

use App\Models\MatchPreference;
use App\Models\MatchResult;
use App\Models\PropertyListing;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Scores published listings against one user's saved preferences and
 * persists the ranked, explainable result set (see plan: "cached, refreshed"
 * — recomputed synchronously on preference save / manual refresh since no
 * queue worker is guaranteed running in this environment).
 *
 * Every scoring factor is skipped entirely (not defaulted to a penalty)
 * when the user hasn't set the relevant preference, and the final score is
 * rescaled against only the factors that actually applied — a listing is
 * never penalized for preferences the user never expressed.
 */
class MatchScorer
{
    private const MAX_CANDIDATES = 300;

    private const MAX_RESULTS = 30;

    // Straight-line distance / assumed average urban travel speed — an
    // estimate, not a routed commute time. Always labelled as such.
    private const ASSUMED_KMH = 20.0;

    private const LIFESTYLE_FACTOR_MAP = [
        'quiet' => ['noise'],
        'safe' => ['safety'],
        'family_friendly' => ['schools', 'safety'],
        'well_connected' => ['transport_access'],
        'low_flood_risk' => ['flood_risk'],
        'good_internet' => ['internet_availability'],
        'vibrant_markets' => ['markets'],
    ];

    public function recompute(MatchPreference $preference): int
    {
        $candidates = $this->candidateQuery($preference)->limit(self::MAX_CANDIDATES)->get();

        $scored = $candidates
            ->map(fn (PropertyListing $listing) => $this->score($listing, $preference))
            ->filter(fn (array $row) => $row['score'] > 0)
            ->sortByDesc('score')
            ->take(self::MAX_RESULTS)
            ->values();

        return DB::transaction(function () use ($preference, $scored) {
            MatchResult::where('user_id', $preference->user_id)->delete();

            $now = now();
            foreach ($scored as $row) {
                MatchResult::create([
                    'user_id' => $preference->user_id,
                    'property_listing_id' => $row['listing']->id,
                    'score' => $row['score'],
                    'reasons' => $row['reasons'],
                    'computed_at' => $now,
                ]);
            }

            return $scored->count();
        });
    }

    private function candidateQuery(MatchPreference $preference)
    {
        $query = PropertyListing::query()
            ->where('status', PropertyListing::STATUS_PUBLISHED)
            ->with([
                'property.address.municipality',
                'property.address.ward',
                'property.address.neighborhood.pois',
                'property.address.neighborhood.score.factors',
                'property.media',
                'trustScore',
            ])
            ->latest('published_at');

        if ($preference->purpose) {
            $query->where('purpose', $preference->purpose);
        }

        $query->whereHas('property', function ($q) use ($preference) {
            if ($preference->property_type) {
                $q->where('property_type', $preference->property_type);
            }
            if ($preference->preferred_municipality_id) {
                $q->whereHas('address', fn ($a) => $a->where('municipality_id', $preference->preferred_municipality_id));
            }
        });

        return $query;
    }

    /** @return array{listing: PropertyListing, score: int, reasons: array<int, array<string, mixed>>} */
    private function score(PropertyListing $listing, MatchPreference $preference): array
    {
        $reasons = [];
        $awarded = 0;
        $maxTotal = 0;

        $add = function (string $label, array $result) use (&$reasons, &$awarded, &$maxTotal) {
            [$points, $max, $explanation] = $result;
            $awarded += $points;
            $maxTotal += $max;
            $reasons[] = ['label' => $label, 'points' => $points, 'max_points' => $max, 'explanation' => $explanation];
        };

        if ($preference->budget_min !== null || $preference->budget_max !== null) {
            $add('Budget fit', $this->budgetFactor($listing, $preference));
        }
        if ($preference->min_bedrooms) {
            $add('Bedrooms', $this->bedroomsFactor($listing, $preference));
        }
        if ($preference->work_lat !== null && $preference->work_lng !== null && $preference->commute_limit_minutes) {
            $add('Commute', $this->commuteFactor($listing, $preference));
        }
        if ($preference->requires_school_nearby) {
            $add('School nearby', $this->schoolFactor($listing));
        }
        if ($preference->requires_parking) {
            $add('Parking', $this->parkingFactor($listing));
        }
        if (! empty($preference->lifestyle_tags)) {
            $add('Lifestyle fit', $this->lifestyleFactor($listing, $preference));
        }
        if ($preference->investment_purpose) {
            $add('Rental demand', $this->investmentFactor($listing));
        }

        $score = $maxTotal > 0 ? (int) round($awarded / $maxTotal * 100) : 0;

        return ['listing' => $listing, 'score' => $score, 'reasons' => $reasons];
    }

    /** @return array{0: int, 1: int, 2: string} */
    private function budgetFactor(PropertyListing $listing, MatchPreference $preference): array
    {
        $max = 25;
        $price = (float) $listing->price;
        $min = $preference->budget_min !== null ? (float) $preference->budget_min : null;
        $maxBudget = $preference->budget_max !== null ? (float) $preference->budget_max : null;

        if ($min !== null && $price < $min) {
            $deficit = $min > 0 ? ($min - $price) / $min : 1;
            $points = max(0, (int) round($max * (1 - min(1, $deficit / 0.3))));

            return [$points, $max, 'NPR ' . number_format($price) . ' is below your minimum budget of NPR ' . number_format($min) . '.'];
        }

        if ($maxBudget !== null && $price > $maxBudget) {
            $excess = $maxBudget > 0 ? ($price - $maxBudget) / $maxBudget : 1;
            $points = max(0, (int) round($max * (1 - min(1, $excess / 0.3))));

            return [$points, $max, 'NPR ' . number_format($price) . ' is above your maximum budget of NPR ' . number_format($maxBudget) . '.'];
        }

        return [$max, $max, 'NPR ' . number_format($price) . ' fits within your budget.'];
    }

    /** @return array{0: int, 1: int, 2: string} */
    private function bedroomsFactor(PropertyListing $listing, MatchPreference $preference): array
    {
        $max = 15;
        $bedrooms = $listing->property?->bedrooms;
        $need = $preference->min_bedrooms;

        if ($bedrooms === null) {
            return [(int) round($max / 2), $max, 'Bedroom count not specified for this listing — starting neutral.'];
        }
        if ($bedrooms >= $need) {
            return [$max, $max, "{$bedrooms} bedroom(s) meets your minimum of {$need}."];
        }

        $diff = $need - $bedrooms;
        $points = max(0, $max - $diff * (int) round($max / 2));

        return [$points, $max, "{$bedrooms} bedroom(s), {$diff} short of your minimum of {$need}."];
    }

    /** @return array{0: int, 1: int, 2: string} */
    private function commuteFactor(PropertyListing $listing, MatchPreference $preference): array
    {
        $max = 20;
        $address = $listing->property?->address;

        if (! $address?->lat || ! $address?->lng) {
            return [0, $max, 'This property has no confirmed map location to estimate commute time.'];
        }

        $distanceKm = $this->haversineKm(
            (float) $preference->work_lat,
            (float) $preference->work_lng,
            (float) $address->lat,
            (float) $address->lng,
        );
        $estimatedMinutes = (int) round($distanceKm / self::ASSUMED_KMH * 60);
        $limit = $preference->commute_limit_minutes;

        if ($estimatedMinutes <= $limit) {
            return [$max, $max, "Estimated ~{$estimatedMinutes} min commute (straight-line estimate), within your {$limit} min limit."];
        }

        $overRatio = $limit > 0 ? ($estimatedMinutes - $limit) / $limit : 1;
        $points = max(0, (int) round($max * (1 - min(1, $overRatio / 0.5))));

        return [$points, $max, "Estimated ~{$estimatedMinutes} min commute (straight-line estimate), over your {$limit} min limit."];
    }

    private function haversineKm(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $earthRadiusKm = 6371;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a = sin($dLat / 2) ** 2 + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadiusKm * $c;
    }

    /** @return array{0: int, 1: int, 2: string} */
    private function schoolFactor(PropertyListing $listing): array
    {
        $max = 10;
        $neighborhood = $listing->property?->address?->neighborhood;

        if (! $neighborhood) {
            return [0, $max, 'No specific neighborhood set for this listing.'];
        }

        $hasSchool = $neighborhood->pois->contains(fn ($poi) => $poi->poi_type === 'school');

        return $hasSchool
            ? [$max, $max, "A school is listed among {$neighborhood->name}'s points of interest."]
            : [0, $max, "No school currently curated for {$neighborhood->name}."];
    }

    /** @return array{0: int, 1: int, 2: string} */
    private function parkingFactor(PropertyListing $listing): array
    {
        $max = 5;
        $spaces = $listing->property?->parking_spaces;
        $type = $listing->property?->parking_type;
        $typeLabel = match ($type) {
            'car' => ' (car)',
            'bike' => ' (bike/scooter)',
            'both' => ' (car & bike)',
            default => '',
        };

        return ($spaces && $spaces > 0)
            ? [$max, $max, "{$spaces} parking space(s) available{$typeLabel}."]
            : [0, $max, 'No parking spaces listed for this property.'];
    }

    /** @return array{0: int, 1: int, 2: string} */
    private function lifestyleFactor(PropertyListing $listing, MatchPreference $preference): array
    {
        $max = 15;
        $tags = $preference->lifestyle_tags ?? [];
        if (empty($tags)) {
            return [0, 0, ''];
        }

        $perTag = $max / count($tags);
        $factorsByKey = $listing->property?->address?->neighborhood?->score?->factors?->keyBy('factor_key') ?? collect();

        $earned = 0.0;
        $notes = [];
        foreach ($tags as $tag) {
            $keys = self::LIFESTYLE_FACTOR_MAP[$tag] ?? [];
            $values = collect($keys)->map(fn ($k) => $factorsByKey->get($k)?->score)->filter(fn ($v) => $v !== null);

            if ($values->isEmpty()) {
                $notes[] = str_replace('_', ' ', $tag) . ': neighborhood not yet scored.';

                continue;
            }

            $avg = $values->avg();
            $earned += ($avg / 10) * $perTag;
            $notes[] = str_replace('_', ' ', $tag) . ": {$avg}/10.";
        }

        return [(int) round($earned), $max, implode(' ', $notes)];
    }

    /** @return array{0: int, 1: int, 2: string} */
    private function investmentFactor(PropertyListing $listing): array
    {
        $max = 10;
        $rentalDemand = $listing->property?->address?->neighborhood?->score?->factors?->firstWhere('factor_key', 'rental_demand');

        if (! $rentalDemand) {
            return [(int) round($max / 2), $max, 'Neighborhood rental demand not yet scored — starting neutral.'];
        }

        $points = (int) round($rentalDemand->score / 10 * $max);

        return [$points, $max, "Neighborhood rental demand rated {$rentalDemand->score}/10."];
    }
}
