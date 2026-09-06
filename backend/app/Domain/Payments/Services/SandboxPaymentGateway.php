<?php

namespace App\Domain\Payments\Services;

use App\Domain\Payments\Contracts\PaymentGateway;
use Illuminate\Support\Str;

/**
 * Dev/test-mode gateway: no real money moves, no external network call. A
 * real transaction still gets created, and the confirm step (normally a
 * processor webhook) is instead triggered directly by the authenticated
 * owner from a clearly-labeled "sandbox checkout" screen — see
 * Owner\PaymentController::confirm(). Swap the app-container binding for a
 * real gateway class implementing the same contract when one is wired up.
 */
class SandboxPaymentGateway implements PaymentGateway
{
    public function generateReference(): string
    {
        return 'SANDBOX-' . strtoupper(Str::random(10));
    }

    public function key(): string
    {
        return 'sandbox';
    }
}
