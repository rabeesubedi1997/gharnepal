<?php

namespace App\Domain\Payments\Contracts;

/**
 * Everything payment-purchase code needs from an external processor, kept
 * deliberately small. A real integration (eSewa/Khalti/ConnectIPS) would
 * implement this same contract — generate a reference the processor will
 * echo back on its callback — and the checkout/confirm flow around it in
 * FeaturedListingPurchaseService would not need to change.
 */
interface PaymentGateway
{
    /** A unique reference for this attempt, to correlate with the eventual callback. */
    public function generateReference(): string;

    /** The gateway key stored on the transaction (e.g. 'sandbox', 'esewa'). */
    public function key(): string;
}
