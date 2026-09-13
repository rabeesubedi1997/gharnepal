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
        Schema::table('properties', function (Blueprint $table) {
            // Vaastu/facing direction and structural notes — optional,
            // owner-entered fields for houses/apartments, matching the
            // architectural detail level of a premium listing without
            // forcing every property to have an opinion on Vaastu.
            $table->string('facing_direction')->nullable()->after('is_furnished');
            $table->unsignedInteger('water_tank_capacity_liters')->nullable()->after('facing_direction');
            $table->text('structural_notes')->nullable()->after('water_tank_capacity_liters');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('properties', function (Blueprint $table) {
            $table->dropColumn(['facing_direction', 'water_tank_capacity_liters', 'structural_notes']);
        });
    }
};
