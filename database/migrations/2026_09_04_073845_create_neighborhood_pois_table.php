<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('neighborhood_pois', function (Blueprint $table) {
            $table->id();
            $table->foreignId('neighborhood_id')->constrained()->cascadeOnDelete();
            $table->enum('poi_type', ['school', 'hospital', 'market', 'transport_stop', 'bank', 'other']);
            $table->string('name');
            $table->decimal('lat', 10, 7)->nullable();
            $table->decimal('lng', 10, 7)->nullable();
            $table->foreignId('added_by')->nullable()->constrained('users')->nullOnDelete();
            $table->boolean('verified')->default(true); // admin-entered POIs are verified by definition
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('neighborhood_pois');
    }
};
