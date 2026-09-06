<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * One row per "page" the site can be searched for — a flat, admin-editable
     * override on top of auto-generated defaults. `page_key` is the single
     * identity a page has everywhere (admin list, editor route, this table):
     * a fixed string for static/category pages ('home', 'buy', 'rent', ...),
     * or "{type}:{identifier}" for dynamic pages ('listing:2bhk-baneshwor',
     * 'neighborhood:12', 'agency:himalayan-homes-realty'). No row existing
     * for a key just means "using the auto-generated defaults" — nothing is
     * ever blank on the live site.
     */
    public function up(): void
    {
        Schema::create('seo_pages', function (Blueprint $table) {
            $table->id();
            $table->string('page_key')->unique();
            $table->enum('page_type', ['static', 'listing', 'neighborhood', 'agency']);
            $table->string('label');
            $table->string('meta_title')->nullable();
            $table->string('meta_description', 320)->nullable();
            $table->string('meta_keywords', 500)->nullable();
            $table->string('og_image_url')->nullable();
            $table->string('canonical_path')->nullable();
            $table->boolean('robots_index')->default(true);
            $table->boolean('robots_follow')->default(true);
            $table->enum('status', ['draft', 'published'])->default('published');
            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index('page_type');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('seo_pages');
    }
};
