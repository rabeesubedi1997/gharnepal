<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('ai_messages', function (Blueprint $table) {
            // Which brain produced this (assistant-role) message —
            // 'rule_based' | 'claude' | 'openai' | 'claude_fallback_rule_based'
            // etc. Null on user-role rows. Purely observational for now.
            $table->string('served_by')->nullable()->after('content');
        });
    }

    public function down(): void
    {
        Schema::table('ai_messages', function (Blueprint $table) {
            $table->dropColumn('served_by');
        });
    }
};
