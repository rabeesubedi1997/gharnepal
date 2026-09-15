<?php

namespace App\Domain\Payments\Services\Drivers;

use App\Domain\Payments\Contracts\PaymentGatewayDriver;
use App\Domain\Payments\Contracts\PaymentInitiation;
use App\Models\PaymentGatewayConfig;
use App\Models\PaymentTransaction;
use RuntimeException;

/**
 * Dev/test-mode gateway: no real money moves, no external network call.
 * The buyer stays on our own "sandbox checkout" screen and self-attests
 * success/failure directly (Owner\PaymentController::confirm — the only
 * gateway that endpoint is allowed to touch, precisely because it's not
 * independently verified by anything external).
 *
 * Refuses to initiate in production unless
 * PAYMENT_GATEWAY_ALLOW_SANDBOX_IN_PRODUCTION=true is set explicitly —
 * otherwise a real deploy could quietly keep forging "successful" payments
 * with real users and no real money ever moving.
 */
class SandboxGatewayDriver implements PaymentGatewayDriver
{
    public static function providerKey(): string
    {
        return 'sandbox';
    }

    public static function label(): string
    {
        return 'Sandbox (test mode, no real money)';
    }

    public static function credentialFields(): array
    {
        return [];
    }

    public function initiate(PaymentGatewayConfig $config, PaymentTransaction $transaction, string $returnUrl): PaymentInitiation
    {
        if (app()->isProduction() && ! config('services.payments.allow_sandbox_in_production')) {
            throw new RuntimeException(
                'Sandbox (buyer-self-attested, no real money) must not run in production. '.
                'Set PAYMENT_GATEWAY_ALLOW_SANDBOX_IN_PRODUCTION=true only if you deliberately intend to '.
                'keep running sandbox/test-mode payments in production.'
            );
        }

        return PaymentInitiation::inline();
    }

    public function verifyCallback(PaymentGatewayConfig $config, PaymentTransaction $transaction, array $query): bool
    {
        // Sandbox never redirects the buyer anywhere external, so nothing
        // ever calls back here — confirmation is the buyer's own self-attest
        // via Owner\PaymentController::confirm instead.
        return false;
    }
}
