<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Any number of rows, each one merchant account/gateway an admin has set
 * up — not a singleton. `provider` picks which driver class handles it
 * (see PaymentGatewayDriverRegistry); `credentials` holds whatever that
 * driver's own credentialFields() schema asks for (merchant code, secret
 * key, client id, ...), encrypted at rest since these are real financial
 * credentials. Adding a new merchant account for an already-supported
 * provider (a second eSewa account, say) is purely an admin-panel action —
 * no deploy. Supporting a genuinely new *provider* still needs one driver
 * class written once (see the Drivers/ directory); this table is what
 * then makes every account of that provider from then on code-free.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payment_gateway_configs', function (Blueprint $table) {
            $table->id();
            $table->string('provider'); // sandbox | manual | esewa | khalti | imepay | paypal
            $table->string('label'); // admin's own name for this config, e.g. "eSewa — main account"
            $table->boolean('is_enabled')->default(false);
            $table->boolean('is_sandbox')->default(true);
            $table->unsignedInteger('sort_order')->default(0);
            $table->text('credentials')->nullable(); // encrypted JSON, shape defined per-provider
            $table->text('instructions')->nullable(); // shown to the buyer — only the 'manual' provider uses this
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('payment_gateway_configs');
    }
};
