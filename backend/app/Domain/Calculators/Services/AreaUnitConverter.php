<?php

namespace App\Domain\Calculators\Services;

use InvalidArgumentException;

/**
 * Single source of truth for area unit conversions. Nepal listings commonly use
 * ropani/aana in the hills (Kathmandu Valley, Pokhara) and kattha/dhur in the
 * Terai (Chitwan, Biratnagar) alongside sqft/sqm — every screen that shows or
 * accepts an area should convert through here rather than hardcoding factors.
 *
 * Conversion factors are Nepal's official survey department constants.
 */
class AreaUnitConverter
{
    private const TO_SQM = [
        'sqm' => 1.0,
        'sqft' => 0.092903,
        'aana' => 31.7949,
        'ropani' => 508.72,
        'kattha' => 338.63,
        'dhur' => 16.93,
    ];

    public static function toSqm(float $value, string $unit): float
    {
        return round($value * self::factor($unit), 2);
    }

    public static function fromSqm(float $sqm, string $unit): float
    {
        return round($sqm / self::factor($unit), 2);
    }

    private static function factor(string $unit): float
    {
        if (! isset(self::TO_SQM[$unit])) {
            throw new InvalidArgumentException("Unknown area unit [{$unit}].");
        }

        return self::TO_SQM[$unit];
    }

    public static function units(): array
    {
        return array_keys(self::TO_SQM);
    }
}
