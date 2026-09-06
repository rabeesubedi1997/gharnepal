<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('neighborhood_score_factors', function (Blueprint $table) {
            $table->id();
            $table->foreignId('neighborhood_score_id')->constrained()->cascadeOnDelete();
            $table->string('factor_key'); // transport_access, schools, hospitals, markets, internet, road_quality, noise, safety, flood_risk, rental_demand, commute_minutes, development_activity
            $table->unsignedTinyInteger('score'); // 0-10 (commute_minutes stores raw minutes instead, see notes column)
            $table->enum('data_source', ['admin', 'community_aggregate'])->default('admin');
            $table->string('notes')->nullable();
            $table->timestamps();

            $table->unique(['neighborhood_score_id', 'factor_key'], 'neighborhood_score_factor_unique');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('neighborhood_score_factors');
    }
};
