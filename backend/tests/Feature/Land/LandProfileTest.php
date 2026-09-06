<?php

namespace Tests\Feature\Land;

use App\Models\Municipality;
use App\Models\Property;
use App\Models\Role;
use App\Models\User;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LandProfileTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    private function landProperty(User $owner): Property
    {
        $municipality = Municipality::where('code', 'M-KTM')->firstOrFail();
        $ward = Ward::where('municipality_id', $municipality->id)->where('ward_number', 1)->firstOrFail();

        $property = Property::create([
            'owner_user_id' => $owner->id,
            'created_by' => $owner->id,
            'property_type' => 'land',
            'total_area_sqm' => 500,
        ]);
        $property->address()->create([
            'province_id' => $municipality->district->province_id,
            'district_id' => $municipality->district_id,
            'municipality_id' => $municipality->id,
            'ward_id' => $ward->id,
        ]);
        $property->managers()->attach($owner->id, ['relation' => 'owner']);

        return $property;
    }

    public function test_owner_can_create_and_update_a_land_due_diligence_profile(): void
    {
        $owner = User::factory()->create();
        $property = $this->landProperty($owner);

        $response = $this->actingAs($owner, 'sanctum')->putJson("/api/v1/properties/{$property->id}/land-profile", [
            'kitta_number' => '123/45',
            'lalpurja_available' => 'yes',
            'road_access' => true,
            'road_width_meters' => 6,
            'road_type' => 'blacktop',
            'water_access' => 'municipal',
            'electricity_access' => true,
            'drainage_access' => 'yes',
            'land_classification' => 'residential',
            'flood_risk' => 'none',
            'landslide_risk' => 'none',
        ]);

        $response->assertSuccessful()
            ->assertJsonPath('data.kitta_number', '123/45')
            ->assertJsonPath('data.lalpurja_available', 'yes')
            ->assertJsonPath('data.completeness_percent', 100);

        $this->assertDatabaseHas('land_profiles', ['property_id' => $property->id, 'kitta_number' => '123/45']);
    }

    public function test_a_non_manager_cannot_edit_someone_elses_land_profile(): void
    {
        $owner = User::factory()->create();
        $property = $this->landProperty($owner);
        $intruder = User::factory()->create();

        $this->actingAs($intruder, 'sanctum')
            ->putJson("/api/v1/properties/{$property->id}/land-profile", ['kitta_number' => 'hijacked'])
            ->assertForbidden();
    }

    public function test_a_land_profile_cannot_be_created_for_a_non_land_property(): void
    {
        $owner = User::factory()->create();
        $property = $this->landProperty($owner);
        $property->update(['property_type' => 'house']);

        $this->actingAs($owner, 'sanctum')
            ->putJson("/api/v1/properties/{$property->id}/land-profile", ['kitta_number' => '1'])
            ->assertUnprocessable();
    }

    public function test_an_admin_can_mark_the_land_documents_as_verified(): void
    {
        $owner = User::factory()->create();
        $property = $this->landProperty($owner);
        $property->landProfile()->create(['kitta_number' => '999/1']);

        $admin = User::factory()->create();
        $admin->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']));

        $response = $this->actingAs($admin, 'sanctum')->patchJson("/api/v1/admin/properties/{$property->id}/land-profile/verify", [
            'document_verification_status' => 'verified',
        ]);

        $response->assertOk()->assertJsonPath('data.document_verification_status', 'verified');
    }

    public function test_the_land_profile_is_visible_on_the_public_listing_when_published(): void
    {
        $owner = User::factory()->create();
        $property = $this->landProperty($owner);
        $property->landProfile()->create(['kitta_number' => '55/2', 'lalpurja_available' => 'yes', 'road_access' => true]);

        $listing = $property->listings()->create([
            'purpose' => 'sale',
            'price' => 5000000,
            'title' => 'Prime residential land plot',
            'slug' => 'prime-residential-land-plot-test',
            'status' => 'published',
            'published_at' => now(),
            'created_by' => $owner->id,
        ]);

        $response = $this->getJson("/api/v1/listings/{$listing->slug}");

        $response->assertOk()
            ->assertJsonPath('data.property.land_profile.kitta_number', '55/2')
            ->assertJsonPath('data.property.land_profile.road_access', true);
    }
}
