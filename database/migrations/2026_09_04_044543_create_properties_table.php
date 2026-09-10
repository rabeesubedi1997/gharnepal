<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('properties', function (Blueprint $table) {
            $table->id();
            $table->foreignId('owner_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->enum('property_type', ['room', 'apartment', 'house', 'land', 'commercial']);

            // Canonical area always in sqm; original entry kept for display fidelity
            // (aana/ropani/kattha/dhur are common outside Kathmandu's core).
            $table->decimal('total_area_sqm', 10, 2)->nullable();
            $table->enum('total_area_unit_entered', ['sqft', 'sqm', 'aana', 'ropani', 'kattha', 'dhur'])->nullable();
            $table->decimal('total_area_value_entered', 10, 2)->nullable();

            $table->unsignedTinyInteger('bedrooms')->nullable();
            $table->unsignedTinyInteger('bathrooms')->nullable();
            $table->unsignedTinyInteger('floors')->nullable();
            $table->unsignedSmallInteger('year_built')->nullable();
            $table->unsignedTinyInteger('parking_spaces')->default(0);
            $table->enum('is_furnished', ['unfurnished', 'semi', 'full'])->nullable();

            $table->foreignId('created_by')->constrained('users');
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('properties');
    }
};
