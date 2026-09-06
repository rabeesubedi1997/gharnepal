<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('match_preferences', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->enum('purpose', ['sale', 'rent'])->nullable();
            $table->enum('property_type', ['room', 'apartment', 'house', 'land', 'commercial'])->nullable();
            $table->decimal('budget_min', 14, 2)->nullable();
            $table->decimal('budget_max', 14, 2)->nullable();
            $table->unsignedTinyInteger('min_bedrooms')->nullable();
            $table->foreignId('preferred_municipality_id')->nullable()->constrained('municipalities')->nullOnDelete();
            // Straight-line commute origin — not a routed/traffic-aware estimate, see MatchScorer.
            $table->decimal('work_lat', 10, 7)->nullable();
            $table->decimal('work_lng', 10, 7)->nullable();
            $table->string('work_location_label')->nullable();
            $table->unsignedSmallInteger('commute_limit_minutes')->nullable();
            $table->unsignedTinyInteger('family_size')->nullable();
            $table->boolean('requires_school_nearby')->default(false);
            $table->boolean('requires_parking')->default(false);
            $table->boolean('investment_purpose')->default(false);
            $table->json('lifestyle_tags')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('match_preferences');
    }
};
