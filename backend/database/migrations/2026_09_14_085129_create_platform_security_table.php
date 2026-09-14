<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Single-row settings table (id 1 only — same pattern as platform_branding)
 * holding the Google reCAPTCHA v2 ("I'm not a robot") keys. Admin-editable
 * instead of hardcoded/.env-only, per the actual ask: nothing currently
 * stops a script from registering unlimited accounts, and the fix has to be
 * something a super admin can turn on/off and rotate without a deploy.
 *
 * recaptcha_enabled defaults to false: registration is NEVER blocked by a
 * captcha check that has no working key configured yet.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('platform_security', function (Blueprint $table) {
            $table->id();
            $table->boolean('recaptcha_enabled')->default(false);
            $table->string('recaptcha_site_key')->nullable();
            $table->string('recaptcha_secret_key')->nullable();
            $table->timestamps();
        });

        DB::table('platform_security')->insert([
            'recaptcha_enabled' => false,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('platform_security');
    }
};
