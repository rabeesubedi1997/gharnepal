<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('seo_competitor_scans', function (Blueprint $table) {
            $table->string('scanned_meta_keywords', 500)->nullable()->after('scanned_meta_description');
            $table->unsignedInteger('word_count')->nullable()->after('scanned_og_image');
        });
    }

    public function down(): void
    {
        Schema::table('seo_competitor_scans', function (Blueprint $table) {
            $table->dropColumn(['scanned_meta_keywords', 'word_count']);
        });
    }
};
