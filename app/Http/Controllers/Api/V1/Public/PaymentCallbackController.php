<?php

namespace App\Http\Controllers\Api\V1\Public;

use App\Domain\Payments\Services\FeaturedListingPurchaseService;
use App\Domain\Payments\Services\PaymentGatewayDriverRegistry;
use App\Http\Controllers\Controller;
use App\Models\PaymentGatewayConfig;
use App\Models\PaymentTransaction;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

/**
 * Where every real gateway (eSewa/Khalti/IME Pay/PayPal) sends the buyer's
 * browser back to after they pay — public, unauthenticated: there's no
 * guarantee of our own session surviving a round trip through another
 * domain, and a couple of these providers verify via a second
 * server-to-server call anyway (no session needed for that either).
 *
 * `?ref=` is appended to every return URL we hand a gateway at initiate
 * time (see FeaturedListingPurchaseService::initiate) and every provider
 * used here preserves an existing query string when appending its own —
 * so this one param reliably identifies the transaction regardless of
 * which provider's own callback shape shows up alongside it.
 */
class PaymentCallbackController extends Controller
{
    public function __construct(private readonly FeaturedListingPurchaseService $purchases) {}

    public function handle(Request $request, PaymentGatewayConfig $gatewayConfig): RedirectResponse
    {
        $frontend = config('app.frontend_url');
        $ref = $request->query('ref');

        $transaction = $ref ? PaymentTransaction::where('gateway_reference', $ref)->first() : null;

        if (! $transaction) {
            return redirect("{$frontend}/account/payments?status=not_found");
        }

        // A provider that fires the return redirect twice (back button,
        // page refresh) must not attempt to confirm an already-settled
        // transaction a second time — just show its current, real status.
        if ($transaction->status !== PaymentTransaction::STATUS_PENDING) {
            $status = $transaction->status === PaymentTransaction::STATUS_COMPLETED ? 'success' : 'failed';

            return redirect("{$frontend}/account/payments?status={$status}");
        }

        $success = false;
        try {
            $driver = PaymentGatewayDriverRegistry::resolve($gatewayConfig->provider);
            $success = $driver->verifyCallback($gatewayConfig, $transaction, $request->query());
        } catch (\Throwable $e) {
            Log::error('Payment callback verification threw', [
                'provider' => $gatewayConfig->provider,
                'transaction_id' => $transaction->id,
                'error' => $e->getMessage(),
            ]);
        }

        $this->purchases->confirm($transaction, $success);

        return redirect("{$frontend}/account/payments?status=".($success ? 'success' : 'failed'));
    }
}
