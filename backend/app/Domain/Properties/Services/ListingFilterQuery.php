<?php

namespace App\Domain\Properties\Services;

use Illuminate\Database\Eloquent\Builder;

/**
 * Applies the public search filter set to a PropertyListing query, from a
 * plain associative array rather than an HTTP Request — so the exact same
 * matching logic can run both for `Public\ListingController::index()` (from
 * `$request->all()`) and for saved-search alert matching (from a
 * `SavedSearch->filters` JSON column, the same shape persisted verbatim).
 * Keeping one implementation means a saved search alert can never silently
 * drift out of sync with what the search page itself considers a match.
 */
class ListingFilterQuery
{
    public static function apply(Builder $query, array $filters): Builder
    {
        $filled = fn (string $key) => array_key_exists($key, $filters)
            && $filters[$key] !== null && $filters[$key] !== '' && $filters[$key] !== [];

        $query->whereHas('property', function (Builder $q) use ($filters, $filled) {
            if ($filled('property_type')) {
                $q->where('property_type', $filters['property_type']);
            }
            if ($filled('bedrooms_min')) {
                $q->where('bedrooms', '>=', (int) $filters['bedrooms_min']);
            }
            if ($filled('parking_type')) {
                $q->where('parking_type', $filters['parking_type']);
            }
            $q->whereHas('address', function (Builder $a) use ($filters, $filled) {
                foreach (['province_id', 'district_id', 'municipality_id', 'ward_id', 'neighborhood_id'] as $field) {
                    if ($filled($field)) {
                        $a->where($field, (int) $filters[$field]);
                    }
                }
                if ($filled('polygon')) {
                    $box = self::boundingBox($filters['polygon']);
                    if ($box !== null) {
                        // A cheap, portable (SQLite-in-tests and MySQL-in-prod
                        // alike) pre-filter down to the polygon's bounding
                        // box — the exact point-in-polygon test itself runs
                        // in PHP afterwards (see matchesPolygon below), since
                        // that needs a real geometry engine that isn't
                        // available on every DB driver this app runs on.
                        $a->whereBetween('lat', [$box['minLat'], $box['maxLat']])
                            ->whereBetween('lng', [$box['minLng'], $box['maxLng']]);
                    }
                }
            });
            if ($filled('lalpurja_available') || $filled('road_access')) {
                $q->whereHas('landProfile', function (Builder $l) use ($filters, $filled) {
                    if ($filled('lalpurja_available')) {
                        $l->where('lalpurja_available', $filters['lalpurja_available']);
                    }
                    if ($filled('road_access')) {
                        $l->where('road_access', filter_var($filters['road_access'], FILTER_VALIDATE_BOOLEAN));
                    }
                });
            }
        });

        if ($filled('purpose')) {
            $query->where('purpose', $filters['purpose']);
        }
        if ($filled('min_price')) {
            $query->where('price', '>=', (float) $filters['min_price']);
        }
        if ($filled('max_price')) {
            $query->where('price', '<=', (float) $filters['max_price']);
        }
        if ($filled('q')) {
            $query->where('title', 'like', '%'.$filters['q'].'%');
        }
        if ($filled('amenity_ids')) {
            $ids = array_map('intval', (array) $filters['amenity_ids']);
            $query->whereHas('amenities', fn (Builder $a) => $a->whereIn('amenities.id', $ids), '=', count($ids));
        }

        return $query;
    }

    /**
     * The exact point-in-polygon refinement `apply()`'s bounding-box
     * pre-filter can't do in SQL. A no-op (true) when `$filters` carries no
     * polygon, or when the listing has no coordinates to test — the bounding
     * box in `apply()` already excluded coordinate-less listings from a
     * polygon search, so this only runs on listings worth re-checking.
     */
    public static function matchesPolygon(array $filters, ?float $lat, ?float $lng): bool
    {
        if (empty($filters['polygon'])) {
            return true;
        }

        if ($lat === null || $lng === null) {
            return false;
        }

        $points = self::parsePoints($filters['polygon']);
        if ($points === null) {
            return true; // an invalid polygon was already rejected at the request-validation layer
        }

        return self::pointInPolygon($lat, $lng, $points);
    }

    /** "lat,lng|lat,lng|..." -> [[lat, lng], ...], or null if unparseable / fewer than 3 points. */
    private static function parsePoints(string $raw): ?array
    {
        $points = [];
        foreach (explode('|', $raw) as $pair) {
            if (! preg_match('/^(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)$/', trim($pair), $m)) {
                return null;
            }
            $lat = (float) $m[1];
            $lng = (float) $m[2];
            if ($lat < -90 || $lat > 90 || $lng < -180 || $lng > 180) {
                return null;
            }
            $points[] = [$lat, $lng];
        }

        return count($points) >= 3 ? $points : null;
    }

    private static function boundingBox(string $raw): ?array
    {
        $points = self::parsePoints($raw);
        if ($points === null) {
            return null;
        }

        $lats = array_column($points, 0);
        $lngs = array_column($points, 1);

        return [
            'minLat' => min($lats), 'maxLat' => max($lats),
            'minLng' => min($lngs), 'maxLng' => max($lngs),
        ];
    }

    /** Standard even-odd ray-casting test. $points is [[lat, lng], ...]. */
    private static function pointInPolygon(float $lat, float $lng, array $points): bool
    {
        $inside = false;
        $count = count($points);

        for ($i = 0, $j = $count - 1; $i < $count; $j = $i++) {
            [$latI, $lngI] = $points[$i];
            [$latJ, $lngJ] = $points[$j];

            $intersects = ($latI > $lat) !== ($latJ > $lat)
                && $lng < ($lngJ - $lngI) * ($lat - $latI) / ($latJ - $latI) + $lngI;

            if ($intersects) {
                $inside = ! $inside;
            }
        }

        return $inside;
    }

    /** Used by request validation to reject an unusable polygon up front. */
    public static function isValidPolygon(string $raw): bool
    {
        return self::parsePoints($raw) !== null;
    }
}
