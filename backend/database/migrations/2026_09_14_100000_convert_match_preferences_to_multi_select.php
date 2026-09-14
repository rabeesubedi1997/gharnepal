<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * `purpose`/`property_type` were single nullable enums — a buyer could only
 * ever describe wanting exactly one transaction type and one property type
 * at a time. User feedback: they want every "service" (Buy/Rent x
 * Room/Apartment/House/Land/Commercial) selectable together in one menu, not
 * forced into two separate single-choice dropdowns. Switched to JSON arrays;
 * MatchScorer::candidateQuery() now uses whereIn() instead of where().
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('match_preferences', function (Blueprint $table) {
            $table->json('purposes')->nullable()->after('purpose');
            $table->json('property_types')->nullable()->after('property_type');
        });

        DB::table('match_preferences')->orderBy('id')->chunkById(100, function ($rows) {
            foreach ($rows as $row) {
                DB::table('match_preferences')->where('id', $row->id)->update([
                    'purposes' => $row->purpose ? json_encode([$row->purpose]) : null,
                    'property_types' => $row->property_type ? json_encode([$row->property_type]) : null,
                ]);
            }
        });

        Schema::table('match_preferences', function (Blueprint $table) {
            $table->dropColumn(['purpose', 'property_type']);
        });
    }

    public function down(): void
    {
        Schema::table('match_preferences', function (Blueprint $table) {
            $table->enum('purpose', ['sale', 'rent'])->nullable()->after('user_id');
            $table->enum('property_type', ['room', 'apartment', 'house', 'land', 'commercial'])->nullable()->after('purpose');
        });

        DB::table('match_preferences')->orderBy('id')->chunkById(100, function ($rows) {
            foreach ($rows as $row) {
                $purposes = json_decode($row->purposes ?? '[]', true) ?: [];
                $types = json_decode($row->property_types ?? '[]', true) ?: [];
                DB::table('match_preferences')->where('id', $row->id)->update([
                    'purpose' => $purposes[0] ?? null,
                    'property_type' => $types[0] ?? null,
                ]);
            }
        });

        Schema::table('match_preferences', function (Blueprint $table) {
            $table->dropColumn(['purposes', 'property_types']);
        });
    }
};
