<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payment_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('property_listing_id')->constrained()->cascadeOnDelete();
            // Static catalog key (see FeaturedListingPlans) — kept as a string
            // rather than an FK since plans are business config, not user data.
            $table->string('plan_key');
            $table->unsignedSmallInteger('plan_days');
            $table->decimal('amount', 10, 2);
            $table->string('currency', 3)->default('NPR');
            // 'sandbox' today; a real gateway ('esewa'/'khalti') slots in later
            // behind the same PaymentGateway contract without a schema change.
            $table->string('gateway')->default('sandbox');
            $table->string('gateway_reference')->unique();
            $table->enum('status', ['pending', 'completed', 'failed', 'refunded'])->default('pending');
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_transactions');
    }
};
