<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('listing_trust_scores', function (Blueprint $table) {
            $table->id();
            $table->foreignId('property_listing_id')->unique()->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('computed_score'); // sum of factor breakdown, always kept even if overridden
            $table->unsignedTinyInteger('total_score'); // computed_score, or the active override's value
            $table->timestamp('computed_at');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('listing_trust_scores');
    }
};
