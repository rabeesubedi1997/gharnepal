<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_provider_configs', function (Blueprint $table) {
            $table->id();
            $table->string('provider')->unique(); // 'claude' | 'openai'
            $table->string('label');
            $table->boolean('is_enabled')->default(false);
            // Laravel's built-in encrypt/decrypt-on-the-fly cast (uses
            // APP_KEY) — same mechanism as PaymentGatewayConfig::credentials,
            // so a real API key never sits in the database in plaintext.
            $table->text('credentials')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_provider_configs');
    }
};
