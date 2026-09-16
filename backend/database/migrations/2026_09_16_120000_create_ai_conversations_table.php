<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_conversations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            // Identifies a guest's own conversation (generated client-side,
            // persisted in localStorage / shared_preferences) so one guest
            // can't read another's conversation by guessing the id.
            $table->string('guest_token')->nullable()->index();
            // The last resolved search filters and result ids — how a
            // stateless rule-based parser supports follow-ups ("cheaper
            // ones", "tell me more about #2") without any model memory.
            $table->json('last_filters')->nullable();
            $table->json('last_listing_ids')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_conversations');
    }
};
