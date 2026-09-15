<?php

namespace App\Http\Controllers\Api\V1\Public;

use App\Http\Controllers\Controller;
use App\Models\PaymentTransaction;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Response;
use Illuminate\View\View;

/**
 * A single URL any client can just open in a browser to actually pay for a
 * transaction — the piece the frontend's own JS normally does for itself
 * (build a hidden auto-submitting form, or follow a redirect URL). The
 * mobile app has no equivalent of that JS, so it opens this URL externally
 * (Custom Tabs / the system browser) instead and lets the browser do it,
 * fed from the `checkout_snapshot` saved at purchase time.
 *
 * Public, unauthenticated, keyed by the gateway reference — same trust
 * model as PaymentCallbackController: nothing here is secret, it's the same
 * amount/product-code/redirect fields the buyer's own browser would carry
 * to the gateway anyway.
 */
class PaymentCheckoutRedirectController extends Controller
{
    public function handle(string $reference): RedirectResponse|View|Response
    {
        $transaction = PaymentTransaction::where('gateway_reference', $reference)->first();

        if (! $transaction || ! $transaction->checkout_snapshot) {
            abort(404, 'Nothing to check out — this payment reference is unknown or already settled without a checkout step.');
        }

        $snapshot = $transaction->checkout_snapshot;

        return match ($snapshot['mode'] ?? null) {
            'redirect' => redirect()->away($snapshot['redirect_url']),
            'form_post' => view('payments.checkout-redirect', [
                'url' => $snapshot['redirect_url'],
                'fields' => $snapshot['form_fields'] ?? [],
            ]),
            // 'inline' (sandbox/manual) never needs a real gateway trip —
            // send whoever ends up here back to their payment history.
            default => redirect(rtrim(config('app.frontend_url'), '/').'/account/payments'),
        };
    }
}
