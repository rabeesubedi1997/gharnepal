<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('cost_calculator_scenarios', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->cascadeOnDelete(); // guests can compute without saving
            $table->foreignId('property_listing_id')->nullable()->constrained()->nullOnDelete();
            $table->enum('type', ['rental', 'purchase']);
            $table->string('name')->nullable();
            $table->json('inputs');
            $table->json('computed_result');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('cost_calculator_scenarios');
    }
};
