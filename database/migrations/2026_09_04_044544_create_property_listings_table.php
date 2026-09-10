<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('property_listings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('property_id')->constrained()->cascadeOnDelete();

            $table->enum('purpose', ['sale', 'rent']);
            $table->decimal('price', 14, 2);
            $table->enum('price_period', ['total', 'monthly'])->nullable();
            $table->string('currency', 3)->default('NPR');
            $table->boolean('negotiable')->default(false);
            $table->date('availability_date')->nullable();

            $table->enum('status', [
                'draft', 'pending_review', 'published', 'paused', 'rented', 'sold', 'rejected', 'expired',
            ])->default('draft');

            $table->string('title');
            $table->string('slug')->unique();
            $table->text('description')->nullable();

            $table->timestamp('published_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            // Admin-set manual promotion for now; the future subscriptions/payments
            // domain will drive this instead of an admin toggle (deferred, see plan).
            $table->timestamp('featured_until')->nullable();

            $table->unsignedInteger('views_count')->default(0);

            $table->foreignId('created_by')->constrained('users');
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->string('rejection_reason')->nullable();

            $table->timestamps();
            $table->softDeletes();

            $table->index(['status', 'purpose']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('property_listings');
    }
};
