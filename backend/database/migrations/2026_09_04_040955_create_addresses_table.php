<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('addresses', function (Blueprint $table) {
            $table->id();
            // Polymorphic owner of the address (initially `properties`, kept generic
            // so other domains — e.g. agency offices — can reuse it later).
            $table->morphs('addressable');

            // Full chain denormalized here so search/filter queries never need a
            // 5-way join to answer "listings in ward X" or "listings in district Y".
            $table->foreignId('province_id')->constrained();
            $table->foreignId('district_id')->constrained();
            $table->foreignId('municipality_id')->constrained();
            $table->foreignId('ward_id')->constrained();
            $table->foreignId('neighborhood_id')->nullable()->constrained();

            $table->string('street_address')->nullable();
            $table->string('landmark')->nullable();
            $table->decimal('lat', 10, 7)->nullable();
            $table->decimal('lng', 10, 7)->nullable();
            $table->string('geohash', 12)->nullable()->index();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('addresses');
    }
};
