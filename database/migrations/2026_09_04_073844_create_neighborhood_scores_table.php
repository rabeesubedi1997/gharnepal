<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('neighborhood_scores', function (Blueprint $table) {
            $table->id();
            $table->foreignId('neighborhood_id')->unique()->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('overall_score'); // 0-10, average of its factors
            $table->enum('source', ['admin_curated', 'blended'])->default('admin_curated');
            $table->timestamp('computed_at');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('neighborhood_scores');
    }
};
