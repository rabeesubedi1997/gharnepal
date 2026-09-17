<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * An admin can now add more than one config for the same provider key
     * (e.g. two separate "custom" OpenAI-compatible agents, or two Claude
     * keys) — only one row total may be `is_enabled` at a time, enforced in
     * AiProviderConfigController, not by this column being unique.
     */
    public function up(): void
    {
        Schema::table('ai_provider_configs', function (Blueprint $table) {
            $table->dropUnique(['provider']);
        });
    }

    public function down(): void
    {
        Schema::table('ai_provider_configs', function (Blueprint $table) {
            $table->unique('provider');
        });
    }
};
