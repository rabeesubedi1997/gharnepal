<?php

namespace App\Domain\Payments\Services;

use App\Domain\Payments\Contracts\PaymentGatewayDriver;
use App\Domain\Payments\Services\Drivers\EsewaGatewayDriver;
use App\Domain\Payments\Services\Drivers\ImePayGatewayDriver;
use App\Domain\Payments\Services\Drivers\KhaltiGatewayDriver;
use App\Domain\Payments\Services\Drivers\ManualGatewayDriver;
use App\Domain\Payments\Services\Drivers\PaypalGatewayDriver;
use App\Domain\Payments\Services\Drivers\SandboxGatewayDriver;
use InvalidArgumentException;

/**
 * The one place that lists which provider keys exist. Adding real support
 * for a brand new provider means writing a driver class and adding one
 * line here — everything downstream (admin form, checkout picker, callback
 * routing) already works off this list generically.
 */
class PaymentGatewayDriverRegistry
{
    /** @var array<string, class-string<PaymentGatewayDriver>> */
    private const DRIVERS = [
        'sandbox' => SandboxGatewayDriver::class,
        'manual' => ManualGatewayDriver::class,
        'esewa' => EsewaGatewayDriver::class,
        'khalti' => KhaltiGatewayDriver::class,
        'imepay' => ImePayGatewayDriver::class,
        'paypal' => PaypalGatewayDriver::class,
    ];

    public static function providerKeys(): array
    {
        return array_keys(self::DRIVERS);
    }

    public static function resolve(string $provider): PaymentGatewayDriver
    {
        $class = self::DRIVERS[$provider] ?? null;

        if (! $class) {
            throw new InvalidArgumentException("Unknown payment provider: {$provider}");
        }

        return app($class);
    }

    /** @return array<int, array{provider: string, label: string, fields: array}> */
    public static function catalog(): array
    {
        return collect(self::DRIVERS)
            ->map(fn (string $class, string $provider) => [
                'provider' => $provider,
                'label' => $class::label(),
                'fields' => $class::credentialFields(),
            ])
            ->values()
            ->all();
    }
}
