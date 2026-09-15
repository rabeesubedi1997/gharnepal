<?php

namespace App\Http\Controllers\Api\V1\Admin;

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

    /**
     * Otherwise read-only oversight — admins see every transaction. The two
     * mutations available are specific, auditable state transitions
     * (`refund`, `markPaid`), never a generic "edit this record" PATCH. The
     * gateway/callback flow still owns pending -> completed/failed for
     * every online gateway exclusively — markPaid exists only because the
     * 'manual' gateway has no callback of its own to do that automatically.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate([
            'status' => ['sometimes', Rule::in(['pending', 'completed', 'failed', 'refunded'])],
        ]);

        $transactions = PaymentTransaction::query()
            ->when($request->filled('status'), fn ($q) => $q->where('status', $request->string('status')))
            ->with(['propertyListing', 'user'])
            ->latest()
            ->paginate(25);

        return PaymentTransactionResource::collection($transactions);
    }

    /**
     * Marks a completed payment refunded. Does not claw back the featured
     * placement already served — same as most real payment processors,
     * a refund reverses the charge, not necessarily the service already
     * rendered. Sandbox gateway: no real money moves either way.
     */
    public function refund(PaymentTransaction $transaction): PaymentTransactionResource
    {
        abort_unless($transaction->status === PaymentTransaction::STATUS_COMPLETED, 422, 'Only a completed payment can be refunded.');

        $transaction->update(['status' => PaymentTransaction::STATUS_REFUNDED]);

        return new PaymentTransactionResource($transaction->load(['propertyListing', 'user']));
    }

    /**
     * For the 'manual' gateway (bank transfer / cash) only — an admin who
     * has actually seen the money arrive confirms it by hand. Refusing this
     * for every other gateway keeps their real, verified callback as the
     * only way those ever complete.
     */
    public function markPaid(PaymentTransaction $transaction): PaymentTransactionResource
    {
        abort_unless($transaction->gateway === 'manual', 422, 'Only a manual-gateway payment can be marked paid by hand.');
        abort_unless($transaction->status === PaymentTransaction::STATUS_PENDING, 422, 'This payment has already been processed.');

        $transaction = $this->purchases->confirm($transaction, true);

        return new PaymentTransactionResource($transaction->load(['propertyListing', 'user']));
    }
}
