<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Persists what `initiate()` handed back so it can be re-served later
     * without calling the gateway driver a second time — a driver like
     * Khalti's calls the provider's own API to create the payment session,
     * so re-running `initiate()` would create a second, orphaned session
     * instead of replaying the first one. This is what lets a client that
     * can't run the frontend's own JS (the mobile app) fetch "how do I pay
     * for this transaction" after the fact via the checkout-redirect route.
     */
    public function up(): void
    {
        Schema::table('payment_transactions', function (Blueprint $table) {
            $table->json('checkout_snapshot')->nullable()->after('gateway_reference');
        });
    }

    public function down(): void
    {
        Schema::table('payment_transactions', function (Blueprint $table) {
            $table->dropColumn('checkout_snapshot');
        });
    }
};
