<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('listing_trust_score_breakdowns', function (Blueprint $table) {
            $table->id();
            $table->foreignId('listing_trust_score_id')->constrained()->cascadeOnDelete();
            $table->foreignId('trust_score_factor_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('points_awarded');
            $table->unsignedTinyInteger('max_points');
            $table->string('explanation'); // human-readable, e.g. "Owner phone verified"
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('listing_trust_score_breakdowns');
    }
};
