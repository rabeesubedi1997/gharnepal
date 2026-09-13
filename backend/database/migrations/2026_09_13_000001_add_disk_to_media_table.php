<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

// Verification documents and land-title (Lalpurja) uploads used to always
// land on the 'public' disk — world-readable at a guessable-prefix URL with
// no auth check at all. New uploads of that kind go to the private 'local'
// disk instead; this column lets Media::url() know which disk a given file
// actually lives on so it can serve a short-lived signed URL for private
// ones instead of a permanent public link. Existing rows default to
// 'public' (their real, current disk) so nothing already stored breaks.
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('media', function (Blueprint $table) {
            $table->string('disk')->default('public')->after('disk_path');
        });
    }

    public function down(): void
    {
        Schema::table('media', function (Blueprint $table) {
            $table->dropColumn('disk');
        });
    }
};
