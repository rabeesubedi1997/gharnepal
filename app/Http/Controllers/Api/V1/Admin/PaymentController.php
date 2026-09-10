<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\PaymentTransactionResource;
use App\Models\PaymentTransaction;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class PaymentController extends Controller
{
    /**
     * Otherwise read-only oversight — admins see every transaction but the
     * only mutation available is `refund`, a specific, auditable state
     * transition (never a generic "edit this record" PATCH). The gateway/
     * confirm flow still owns pending -> completed/failed exclusively.
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
}
