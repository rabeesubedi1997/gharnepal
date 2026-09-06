<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('visit_verifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('viewing_request_id')->unique()->constrained()->cascadeOnDelete();
            $table->boolean('visited');
            $table->boolean('matched_listing')->nullable();
            $table->boolean('price_accurate')->nullable();
            $table->boolean('host_attended')->nullable();
            $table->boolean('documents_shown')->nullable();
            $table->text('overall_comment')->nullable();
            $table->foreignId('submitted_by')->constrained('users');
            $table->timestamp('submitted_at');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('visit_verifications');
    }
};
