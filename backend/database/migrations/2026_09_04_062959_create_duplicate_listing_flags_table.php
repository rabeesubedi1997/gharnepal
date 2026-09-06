<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('duplicate_listing_flags', function (Blueprint $table) {
            $table->id();
            $table->foreignId('property_listing_id')->constrained()->cascadeOnDelete();
            $table->foreignId('duplicate_of_listing_id')->constrained('property_listings')->cascadeOnDelete();
            $table->unsignedTinyInteger('match_score'); // 0-100, see DuplicateListingDetector
            $table->json('match_reasons'); // e.g. ["same_owner_phone", "same_ward", "similar_price"]
            $table->enum('status', ['unreviewed', 'confirmed', 'dismissed'])->default('unreviewed');
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->unique(['property_listing_id', 'duplicate_of_listing_id'], 'duplicate_flags_pair_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('duplicate_listing_flags');
    }
};
