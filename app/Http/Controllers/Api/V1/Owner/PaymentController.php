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
     * Sandbox-only stand-in for a real gateway's server-to-server callback:
     * the transaction's own owner triggers it from the sandbox checkout
     * screen. A real gateway integration would replace this with a signed
     * webhook endpoint instead — the FeaturedListingPurchaseService logic
     * underneath does not change either way.
     */
    public function confirm(Request $request, PaymentTransaction $transaction): PaymentTransactionResource
    {
        if ($transaction->user_id !== $request->user()->id) {
            abort(403);
        }

        $data = $request->validate([
            'outcome' => ['required', Rule::in(['success', 'failure'])],
        ]);

        $transaction = $this->purchases->confirm($transaction, $data['outcome'] === 'success');

        return new PaymentTransactionResource($transaction->load('propertyListing'));
    }
}
