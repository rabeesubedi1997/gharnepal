<?php

namespace App\Domain\Payments\Services;

/**
 * Static pricing catalog for listing-boost purchases. Kept as versioned
 * code rather than an admin-editable DB table on purpose: this is business
 * pricing config (like AreaUnitConverter's conversion constants), not
 * user-generated content — changing prices is a deliberate release, not a
 * runtime admin action.
 */
class FeaturedListingPlans
{
    public const PLANS = [
        'boost_7' => ['days' => 7, 'price' => 500.00, 'label' => '7-day boost'],
        'boost_15' => ['days' => 15, 'price' => 900.00, 'label' => '15-day boost'],
        'boost_30' => ['days' => 30, 'price' => 1600.00, 'label' => '30-day boost'],
    ];

    /** @return array<int, array{key: string, days: int, price: float, label: string}> */
    public static function all(): array
    {
        return collect(self::PLANS)
            ->map(fn ($plan, $key) => [...$plan, 'key' => $key])
            ->values()
            ->all();
    }

    public static function find(string $key): ?array
    {
        return self::PLANS[$key] ?? null;
    }
}
