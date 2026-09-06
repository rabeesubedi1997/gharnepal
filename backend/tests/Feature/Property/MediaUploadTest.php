<?php

namespace Tests\Feature\Property;

use App\Models\Municipality;
use App\Models\Property;
use App\Models\User;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class MediaUploadTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, NepalLocationSeeder::class]);
        Storage::fake('public');
    }

    private function createProperty(User $owner): Property
    {
        $municipality = Municipality::where('code', 'M-KTM')->firstOrFail();
        $ward = Ward::where('municipality_id', $municipality->id)->first();

        $property = Property::create([
            'owner_user_id' => $owner->id,
            'created_by' => $owner->id,
            'property_type' => 'apartment',
            'total_area_sqm' => 100,
        ]);

        $property->address()->create([
            'province_id' => $municipality->district->province_id,
            'district_id' => $municipality->district_id,
            'municipality_id' => $municipality->id,
            'ward_id' => $ward->id,
        ]);

        return $property;
    }

    public function test_owner_can_upload_a_photo_to_their_property(): void
    {
        $owner = User::factory()->create();
        $property = $this->createProperty($owner);

        $response = $this->actingAs($owner, 'sanctum')->postJson("/api/v1/properties/{$property->id}/media", [
            'type' => 'image',
            'file' => UploadedFile::fake()->image('living-room.jpg', 1200, 800),
        ]);

        $response->assertCreated()->assertJsonPath('data.type', 'image');
        $this->assertDatabaseHas('media', ['mediable_id' => $property->id, 'mediable_type' => Property::class]);
    }

    public function test_a_non_manager_cannot_upload_to_someone_elses_property(): void
    {
        $owner = User::factory()->create();
        $property = $this->createProperty($owner);
        $intruder = User::factory()->create();

        $this->actingAs($intruder, 'sanctum')->postJson("/api/v1/properties/{$property->id}/media", [
            'type' => 'image',
            'file' => UploadedFile::fake()->image('photo.jpg'),
        ])->assertForbidden();
    }

    public function test_a_pdf_is_rejected_as_an_image(): void
    {
        $owner = User::factory()->create();
        $property = $this->createProperty($owner);

        $this->actingAs($owner, 'sanctum')->postJson("/api/v1/properties/{$property->id}/media", [
            'type' => 'image',
            'file' => UploadedFile::fake()->create('doc.pdf', 100, 'application/pdf'),
        ])->assertUnprocessable();
    }
}
