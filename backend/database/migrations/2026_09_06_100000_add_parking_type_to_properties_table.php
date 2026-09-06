<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('properties', function (Blueprint $table) {
            // Only meaningful when parking_spaces > 0 — Nepal rentals commonly
            // distinguish car parking (needs a real bay) from bike/scooter
            // parking (much more common for rooms/flats), so a single count
            // was never enough to answer "can I park my bike here?".
            $table->enum('parking_type', ['car', 'bike', 'both'])->nullable()->after('parking_spaces');
        });
    }

    public function down(): void
    {
        Schema::table('properties', function (Blueprint $table) {
            $table->dropColumn('parking_type');
        });
    }
};
