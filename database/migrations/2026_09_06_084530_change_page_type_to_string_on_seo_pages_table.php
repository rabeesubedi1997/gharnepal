<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * page_type started as an enum('static','listing','neighborhood','agency'),
     * which means every new page type (this migration adds 'blog') needs a
     * schema change just to widen the allowed values — and MySQL enum
     * ALTERs are exactly the kind of change that's awkward across MySQL vs
     * SQLite (the test DB). Validated in the application layer instead
     * (SeoService/Admin\SeoController already only ever write known values),
     * so the column itself no longer needs to change every time a new page
     * type is added.
     */
    public function up(): void
    {
        Schema::table('seo_pages', function (Blueprint $table) {
            $table->string('page_type', 30)->change();
        });
    }

    public function down(): void
    {
        Schema::table('seo_pages', function (Blueprint $table) {
            $table->enum('page_type', ['static', 'listing', 'neighborhood', 'agency'])->change();
        });
    }
};
