<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('land_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('property_id')->unique()->constrained()->cascadeOnDelete();

            $table->string('kitta_number')->nullable();
            $table->enum('lalpurja_available', ['yes', 'no', 'in_process', 'unknown'])->default('unknown');
            $table->foreignId('lalpurja_document_media_id')->nullable()->constrained('media')->nullOnDelete();

            $table->boolean('road_access')->default(false);
            $table->decimal('road_width_meters', 5, 2)->nullable();
            $table->enum('road_type', ['blacktop', 'gravel', 'dirt', 'none'])->default('none');

            $table->enum('water_access', ['municipal', 'well', 'none', 'unknown'])->default('unknown');
            $table->boolean('electricity_access')->default(false);
            $table->enum('drainage_access', ['yes', 'no', 'unknown'])->default('unknown');

            $table->enum('land_classification', ['residential', 'agricultural', 'commercial', 'guthi', 'other'])->default('residential');
            $table->enum('flood_risk', ['none', 'low', 'medium', 'high', 'unknown'])->default('unknown');
            $table->enum('landslide_risk', ['none', 'low', 'medium', 'high', 'unknown'])->default('unknown');
            $table->text('nearby_development_notes')->nullable();

            // "Verified" here means an admin reviewed the submitted lalpurja/kitta
            // details — never a government land-registry confirmation. Keep that
            // distinction explicit in the UI copy (see plan risk: self-reported data).
            $table->enum('document_verification_status', ['unverified', 'partial', 'verified'])->default('unverified');
            $table->foreignId('verified_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('verified_at')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('land_profiles');
    }
};
