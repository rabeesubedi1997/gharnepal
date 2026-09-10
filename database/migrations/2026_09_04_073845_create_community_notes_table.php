<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('community_notes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('neighborhood_id')->constrained()->cascadeOnDelete();
            $table->foreignId('submitted_by')->constrained('users')->cascadeOnDelete();
            $table->enum('category', [
                'water_supply', 'power_interruption', 'road_condition', 'isp_quality',
                'parking_difficulty', 'seasonal_flooding', 'noise', 'market_access', 'other',
            ]);
            // Length-capped, no attachments — limits how much PII free text can carry
            // (see plan risk: community-content moderation / PII exposure).
            $table->string('body', 500);
            $table->enum('status', ['pending', 'approved', 'rejected', 'flagged_removed'])->default('pending');
            $table->foreignId('moderated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('moderated_at')->nullable();
            $table->string('rejection_reason')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('community_notes');
    }
};
