<?php

namespace App\Domain\Payments\Services;

use App\Domain\Payments\Contracts\PaymentGateway;
use App\Models\PaymentTransaction;
use App\Models\PropertyListing;
use App\Models\User;
use App\Notifications\FeaturedListingActivatedNotification;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class FeaturedListingPurchaseService
{
    public function __construct(private readonly PaymentGateway $gateway) {}

    public function initiate(PropertyListing $listing, User $user, string $planKey): PaymentTransaction
    {
        $plan = FeaturedListingPlans::find($planKey);

        if (! $plan) {
            throw ValidationException::withMessages(['plan_key' => 'Unknown boost plan.']);
        }

        return PaymentTransaction::create([
            'user_id' => $user->id,
            'property_listing_id' => $listing->id,
            'plan_key' => $planKey,
            'plan_days' => $plan['days'],
            'amount' => $plan['price'],
            'currency' => 'NPR',
            'gateway' => $this->gateway->key(),
            'gateway_reference' => $this->gateway->generateReference(),
            'status' => PaymentTransaction::STATUS_PENDING,
        ]);
    }

    /**
     * Stands in for a gateway webhook: applies the listing boost on success,
     * or simply marks the attempt failed. Idempotent — a transaction can
     * only be confirmed once from 'pending'.
     */
    public function confirm(PaymentTransaction $transaction, bool $success): PaymentTransaction
    {
        if ($transaction->status !== PaymentTransaction::STATUS_PENDING) {
            throw ValidationException::withMessages(['status' => 'This payment has already been processed.']);
        }

        if (! $success) {
            $transaction->update(['status' => PaymentTransaction::STATUS_FAILED]);

            return $transaction;
        }

        return DB::transaction(function () use ($transaction) {
            $transaction->update(['status' => PaymentTransaction::STATUS_COMPLETED, 'completed_at' => now()]);

            $listing = $transaction->propertyListing;
            // Stack onto remaining boost time if still active, rather than
            // resetting the clock — buying another boost should extend, not waste, time already paid for.
            $base = ($listing->featured_until && $listing->featured_until->isFuture()) ? $listing->featured_until : now();
            $listing->update(['featured_until' => $base->copy()->addDays($transaction->plan_days)]);

            $listing->property?->owner?->notify(new FeaturedListingActivatedNotification($listing->fresh()));

            return $transaction->fresh();
        });
    }
}
