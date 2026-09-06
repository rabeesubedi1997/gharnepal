<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Read-only reference snapshots of a competitor page's SEO signals
     * (title/description/headings/keywords — never the full body text),
     * attached to one of our own pages via `page_key`. Purely informational:
     * an admin looks at a scan, edits the SeoPage fields themselves, and
     * either publishes or discards — a scan never writes to seo_pages on
     * its own.
     */
    public function up(): void
    {
        Schema::create('seo_competitor_scans', function (Blueprint $table) {
            $table->id();
            $table->string('page_key')->index();
            $table->string('competitor_url', 1000);
            $table->string('scanned_title')->nullable();
            $table->string('scanned_meta_description', 500)->nullable();
            $table->json('scanned_headings')->nullable();
            $table->json('scanned_keywords')->nullable();
            $table->string('scanned_og_image')->nullable();
            $table->enum('status', ['pending', 'discarded'])->default('pending');
            $table->foreignId('scanned_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('seo_competitor_scans');
    }
};
