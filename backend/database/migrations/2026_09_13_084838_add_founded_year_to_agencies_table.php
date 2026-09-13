<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('agencies', function (Blueprint $table) {
            // Self-reported by the agency, shown as "Operating since {year}"
            // on its dashboard/profile — real disclosed data, not inferred
            // from when the agency happened to sign up on this platform.
            $table->unsignedSmallInteger('founded_year')->nullable()->after('registration_number');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('agencies', function (Blueprint $table) {
            $table->dropColumn('founded_year');
        });
    }
};
