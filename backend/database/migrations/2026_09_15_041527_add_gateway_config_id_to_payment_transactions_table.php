<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Which specific merchant account (PaymentGatewayConfig row) this
 * transaction went through — needed once more than one config can exist
 * per provider (two eSewa merchant accounts, say). Nullable: existing
 * sandbox transactions predate gateway configs entirely, and a config
 * being deleted later must not cascade-delete transaction history.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('payment_transactions', function (Blueprint $table) {
            $table->foreignId('gateway_config_id')->nullable()->after('gateway')
                ->constrained('payment_gateway_configs')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('payment_transactions', function (Blueprint $table) {
            $table->dropConstrainedForeignId('gateway_config_id');
        });
    }
};
