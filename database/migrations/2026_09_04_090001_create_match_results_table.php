<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('match_results', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('property_listing_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('score'); // 0-100, see MatchScorer for the per-factor breakdown that produced it
            $table->json('reasons'); // [{label, points, max_points, explanation}, ...] — explainable, same spirit as trust scoring
            $table->timestamp('computed_at');
            $table->timestamps();

            $table->unique(['user_id', 'property_listing_id'], 'match_results_user_listing_unique');
            $table->index(['user_id', 'score']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('match_results');
    }
};
