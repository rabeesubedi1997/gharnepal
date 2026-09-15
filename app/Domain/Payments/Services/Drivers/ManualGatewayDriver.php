<?php

namespace App\Domain\Payments\Services\Drivers;

use App\Domain\Payments\Contracts\PaymentGatewayDriver;
use App\Domain\Payments\Contracts\PaymentInitiation;
use App\Models\PaymentGatewayConfig;
use App\Models\PaymentTransaction;

/**
 * "Pay the owner directly" / bank transfer / cash — no API of any kind.
 * The buyer sees whatever free-text instructions the admin wrote on the
 * config (account number, wallet handle, office address, ...) and the
 * transaction sits 'pending' until an admin marks it paid by hand
 * (Admin\PaymentController::markPaid) once they've actually seen the money
 * arrive. Exists so a merchant with no online gateway account yet can
 * still accept payments from day one.
 */
class ManualGatewayDriver implements PaymentGatewayDriver
{
    public static function providerKey(): string
    {
        return 'manual';
    }

    public static function label(): string
    {
        return 'Manual (bank transfer / cash — admin confirms by hand)';
    }

    public static function credentialFields(): array
    {
        return [];
    }

    public function initiate(PaymentGatewayConfig $config, PaymentTransaction $transaction, string $returnUrl): PaymentInitiation
    {
        return PaymentInitiation::inline($config->instructions);
    }

    public function verifyCallback(PaymentGatewayConfig $config, PaymentTransaction $transaction, array $query): bool
    {
        // No external redirect ever happens for a manual gateway.
        return false;
    }
}
