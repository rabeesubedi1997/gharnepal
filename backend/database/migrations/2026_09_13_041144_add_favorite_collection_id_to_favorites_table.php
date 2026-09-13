<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('favorites', function (Blueprint $table) {
            // Nullable: a favorite with no collection just sits in "All saved" —
            // grouping into a named, shareable collection is opt-in.
            $table->foreignId('favorite_collection_id')->nullable()->after('property_listing_id')
                ->constrained('favorite_collections')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('favorites', function (Blueprint $table) {
            $table->dropConstrainedForeignId('favorite_collection_id');
        });
    }
};
