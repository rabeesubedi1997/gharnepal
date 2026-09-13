<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('favorite_collections', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            // The unguessable key a collection is shared by — anyone holding
            // the link can view it read-only, no login required (same
            // capability-URL model used by, e.g., a Google Doc's share link).
            // There's no separate "make public" toggle: generating and
            // handing out this link *is* the publish action.
            $table->string('share_token', 32)->unique();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('favorite_collections');
    }
};
