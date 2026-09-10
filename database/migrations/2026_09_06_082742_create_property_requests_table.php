<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * A demand-side board: a buyer/renter posts what they're looking for
     * instead of only reacting to sellers' listings. An owner/agent who has
     * something matching responds via the same Conversation/messaging system
     * listings use (see the conversations table migration alongside this one).
     */
    public function up(): void
    {
        Schema::create('property_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->enum('purpose', ['sale', 'rent']);
            $table->enum('property_type', ['room', 'apartment', 'house', 'land', 'commercial'])->nullable();
            $table->unsignedBigInteger('budget_min')->nullable();
            $table->unsignedBigInteger('budget_max')->nullable();
            $table->unsignedTinyInteger('bedrooms_min')->nullable();
            $table->foreignId('municipality_id')->nullable()->constrained()->nullOnDelete();
            $table->string('notes', 1000)->nullable();
            $table->enum('status', ['open', 'closed'])->default('open');
            $table->timestamps();

            $table->index(['status', 'purpose']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('property_requests');
    }
};
