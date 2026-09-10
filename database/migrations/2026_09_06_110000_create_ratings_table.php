<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ratings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            // Polymorphic on purpose, even though only PropertyListing is
            // wired up today — an Agency profile rating is a natural,
            // near-zero-cost follow-up on the same table.
            $table->string('rateable_type');
            $table->unsignedBigInteger('rateable_id');
            $table->unsignedTinyInteger('score'); // 1-5
            $table->string('comment', 500)->nullable();
            // Immediately visible on submit (no pre-moderation queue, matching
            // how Google/Zillow reviews work) — admin can hide one after the
            // fact instead, see Admin\RatingController.
            $table->enum('status', ['visible', 'hidden'])->default('visible');
            $table->timestamps();

            $table->unique(['user_id', 'rateable_type', 'rateable_id'], 'ratings_user_rateable_unique');
            $table->index(['rateable_type', 'rateable_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ratings');
    }
};
