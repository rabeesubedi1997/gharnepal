<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * A conversation now has two possible contexts, not just one: a listing
     * inquiry (unchanged) or a response to a property request. Exactly one of
     * property_listing_id / property_request_id is set — enforced at the
     * application layer (MessagingService), not a DB constraint, since MySQL
     * has no portable "exactly one of these columns is null" check without a
     * generated column.
     */
    public function up(): void
    {
        Schema::table('conversations', function (Blueprint $table) {
            $table->dropForeign(['property_listing_id']);
        });

        Schema::table('conversations', function (Blueprint $table) {
            $table->unsignedBigInteger('property_listing_id')->nullable()->change();
        });

        Schema::table('conversations', function (Blueprint $table) {
            $table->foreign('property_listing_id')->references('id')->on('property_listings')->cascadeOnDelete();

            $table->foreignId('property_request_id')->nullable()->after('property_listing_id')
                ->constrained()->cascadeOnDelete();

            // A given responder gets one thread per request (buyer_user_id is
            // already fixed to the request's own owner, so this is enough).
            $table->unique(['property_request_id', 'owner_user_id']);
        });
    }

    public function down(): void
    {
        Schema::table('conversations', function (Blueprint $table) {
            $table->dropUnique(['property_request_id', 'owner_user_id']);
            $table->dropConstrainedForeignId('property_request_id');
            $table->dropForeign(['property_listing_id']);
        });

        Schema::table('conversations', function (Blueprint $table) {
            $table->unsignedBigInteger('property_listing_id')->nullable(false)->change();
        });

        Schema::table('conversations', function (Blueprint $table) {
            $table->foreign('property_listing_id')->references('id')->on('property_listings')->cascadeOnDelete();
        });
    }
};
