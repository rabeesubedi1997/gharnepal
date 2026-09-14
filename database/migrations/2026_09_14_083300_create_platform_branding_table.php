<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Single-row settings table (id 1 only, enforced in PlatformBranding::current())
 * — the site name, web favicon, and the *source* image for the native mobile
 * app icon, all editable from the admin panel instead of baked into code.
 *
 * The web favicon applies live (the frontend swaps <link rel="icon"> at
 * runtime from GET /branding). The app icon cannot: Android/iOS bake a
 * launcher icon into the compiled app at build time — no live update is
 * technically possible without a new release. Storing it here still has
 * real value: it's the one place that source image lives, so "next build
 * uses this" instead of icon files scattered across a repo.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('platform_branding', function (Blueprint $table) {
            $table->id();
            $table->string('site_name')->default('Ghar Nepal');
            $table->string('favicon_path')->nullable();
            $table->string('app_icon_path')->nullable();
            $table->timestamps();
        });

        DB::table('platform_branding')->insert([
            'site_name' => 'Ghar Nepal',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('platform_branding');
    }
};
