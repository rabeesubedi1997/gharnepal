<?php

namespace Tests\Feature\Property;

use App\Models\Municipality;
use App\Models\Role;
use App\Models\User;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PropertyCreationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, NepalLocationSeeder::class]);
    }

    private function addressPayload(): array
    {
        $ward = Ward::query()->whereHas('municipality', fn ($q) => $q->where('code', 'M-KTM'))->first();
        $municipality = Municipality::where('code', 'M-KTM')->firstOrFail();

        return [
            'province_id' => $municipality->district->province_id,
            'district_id' => $municipality->district_id,
            'municipality_id' => $municipality->id,
            'ward_id' => $ward->id,
        ];
    }

    public function test_a_user_can_create_a_property_and_becomes_its_owner(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/v1/properties', [
            'property_type' => 'apartment',
            'area_value' => 1200,
            'area_unit' => 'sqft',
            'bedrooms' => 3,
            'bathrooms' => 2,
            'address' => $this->addressPayload(),
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.property_type', 'apartment')
            ->assertJsonPath('data.bedrooms', 3);

        $this->assertDatabaseHas('properties', ['created_by' => $user->id, 'owner_user_id' => $user->id]);
        $this->assertTrue($user->fresh()->hasRole(Role::OWNER));

        $property = \App\Models\Property::where('created_by', $user->id)->firstOrFail();
        $this->assertDatabaseHas('addresses', [
            'addressable_id' => $property->id,
            'addressable_type' => \App\Models\Property::class,
        ]);
    }

    public function test_residential_property_types_require_bedrooms(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/v1/properties', [
            'property_type' => 'house',
            'area_value' => 5,
            'area_unit' => 'aana',
            'address' => $this->addressPayload(),
        ]);

        $response->assertUnprocessable()->assertJsonValidationErrors('bedrooms');
    }

    public function test_land_does_not_require_bedrooms(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/v1/properties', [
            'property_type' => 'land',
            'area_value' => 5,
            'area_unit' => 'aana',
            'address' => $this->addressPayload(),
        ]);

        $response->assertCreated();
    }

    public function test_guests_cannot_create_properties(): void
    {
        $this->postJson('/api/v1/properties', [])->assertUnauthorized();
    }

    public function test_a_property_can_specify_parking_type(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/v1/properties', [
            'property_type' => 'room',
            'area_value' => 150,
            'area_unit' => 'sqft',
            'bedrooms' => 1,
            'bathrooms' => 1,
            'parking_spaces' => 2,
            'parking_type' => 'bike',
            'address' => $this->addressPayload(),
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.parking_spaces', 2)
            ->assertJsonPath('data.parking_type', 'bike');
    }

    public function test_an_invalid_parking_type_is_rejected(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')->postJson('/api/v1/properties', [
            'property_type' => 'room',
            'area_value' => 150,
            'area_unit' => 'sqft',
            'bedrooms' => 1,
            'bathrooms' => 1,
            'parking_type' => 'helicopter',
            'address' => $this->addressPayload(),
        ])->assertUnprocessable();
    }
}
