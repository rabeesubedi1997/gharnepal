<?php

namespace App\Http\Controllers\Api\V1\Owner;

use App\Domain\Payments\Services\FeaturedListingPurchaseService;
use App\Http\Controllers\Controller;
use App\Http\Resources\PaymentTransactionResource;
use App\Models\PaymentTransaction;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class PaymentController extends Controller
{
    public function __construct(private readonly FeaturedListingPurchaseService $purchases) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $transactions = PaymentTransaction::query()
            ->where('user_id', $request->user()->id)
            ->with('propertyListing')
            ->latest()
            ->paginate(20);

        return PaymentTransactionResource::collection($transactions);
    }

    /**
     * Sandbox-only: the buyer self-attests success/failure directly, since
     * nothing external verifies a sandbox transaction. Every real gateway
     * (eSewa/Khalti/IME Pay/PayPal) is confirmed exclusively through its
     * own signed/verified callback (see PaymentCallbackController) —
     * letting a buyer call this endpoint for a *real* transaction would
     * mean anyone could just claim their own payment succeeded and get the
     * boost for free, so it's hard-rejected for any gateway but sandbox.
     */
    public function confirm(Request $request, PaymentTransaction $transaction): PaymentTransactionResource
    {
        if ($transaction->user_id !== $request->user()->id) {
            abort(403);
        }

        abort_unless($transaction->gateway === 'sandbox', 422, 'This payment method confirms automatically and cannot be confirmed manually.');

        $data = $request->validate([
            'outcome' => ['required', Rule::in(['success', 'failure'])],
        ]);

        $transaction = $this->purchases->confirm($transaction, $data['outcome'] === 'success');

        return new PaymentTransactionResource($transaction->load('propertyListing'));
    }
}
