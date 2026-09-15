<?php

namespace App\Domain\Payments\Contracts;

use App\Models\PaymentGatewayConfig;
use App\Models\PaymentTransaction;

/**
 * What every payment provider integration implements. A new *provider*
 * (one not already on this list) means writing one class implementing
 * this contract, once — after that, any number of merchant accounts for
 * it are pure admin-panel configuration (PaymentGatewayConfig rows), no
 * further code. See PaymentGatewayDriverRegistry for the provider => class
 * map, and each Drivers/*.php file's own docblock for that provider's API.
 */
interface PaymentGatewayDriver
{
    /** Unique provider key this driver handles, e.g. 'esewa'. Matches PaymentGatewayConfig::provider. */
    public static function providerKey(): string;

    public static function label(): string;

    /**
     * What the admin form needs to collect for a config using this
     * provider — drives both the admin UI's dynamic form and this driver's
     * own validation of what it's given.
     *
     * @return array<int, array{key: string, label: string, type: 'text'|'password', required: bool}>
     */
    public static function credentialFields(): array;

    /**
     * Kick off a payment attempt: build/sign whatever this provider needs
     * and return the shape the frontend acts on. May call the provider's
     * API (Khalti, PayPal); may just build a signed form (eSewa); may do
     * nothing external at all (sandbox/manual).
     */
    public function initiate(PaymentGatewayConfig $config, PaymentTransaction $transaction, string $returnUrl): PaymentInitiation;

    /**
     * Interpret + independently verify an inbound return/callback for this
     * provider (a signature check, and/or a server-to-server status call
     * back to the provider) — never trust the redirect query alone. Returns
     * whether the payment actually succeeded.
     */
    public function verifyCallback(PaymentGatewayConfig $config, PaymentTransaction $transaction, array $query): bool;
}
