<?php

namespace Tests\Feature\Property;

use App\Models\Municipality;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\Role;
use App\Models\User;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PropertyListingLifecycleTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, NepalLocationSeeder::class]);
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
            'bedrooms' => 2,
            'bathrooms' => 1,
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

    public function test_owner_can_create_a_draft_listing_and_submit_it_for_review(): void
    {
        $owner = User::factory()->create();
        $property = $this->createProperty($owner);

        $create = $this->actingAs($owner, 'sanctum')->postJson("/api/v1/properties/{$property->id}/listings", [
            'purpose' => 'rent',
            'price' => 25000,
            'price_period' => 'monthly',
            'title' => 'Cozy 2BHK in Kathmandu',
        ]);

        $create->assertCreated()->assertJsonPath('data.status', 'draft');
        $listingId = $create->json('data.id');

        $submit = $this->actingAs($owner, 'sanctum')
            ->patchJson("/api/v1/owner/listings/{$listingId}/transition", ['action' => 'submit']);

        $submit->assertOk()->assertJsonPath('data.status', 'pending_review');
    }

    public function test_a_pending_listing_is_not_publicly_visible_until_admin_approves_it(): void
    {
        $owner = User::factory()->create();
        $property = $this->createProperty($owner);
        $listing = PropertyListing::create([
            'property_id' => $property->id,
            'purpose' => 'sale',
            'price' => 15000000,
            'title' => 'Beautiful Family Home',
            'slug' => 'beautiful-family-home-test',
            'status' => PropertyListing::STATUS_PENDING_REVIEW,
            'created_by' => $owner->id,
        ]);

        $this->getJson('/api/v1/listings/beautiful-family-home-test')->assertNotFound();

        $admin = User::factory()->create();
        $admin->roles()->attach(Role::where('key', Role::ADMIN)->first());

        $approve = $this->actingAs($admin, 'sanctum')
            ->patchJson("/api/v1/admin/listings/{$listing->id}/approve");
        $approve->assertOk()->assertJsonPath('data.status', 'published');

        $this->getJson('/api/v1/listings/beautiful-family-home-test')
            ->assertOk()
            ->assertJsonPath('data.title', 'Beautiful Family Home');
    }

    public function test_non_admin_cannot_approve_listings(): void
    {
        $owner = User::factory()->create();
        $property = $this->createProperty($owner);
        $listing = PropertyListing::create([
            'property_id' => $property->id,
            'purpose' => 'sale',
            'price' => 1000000,
            'title' => 'Test listing',
            'slug' => 'test-listing-forbidden',
            'status' => PropertyListing::STATUS_PENDING_REVIEW,
            'created_by' => $owner->id,
        ]);

        $someoneElse = User::factory()->create();

        $this->actingAs($someoneElse, 'sanctum')
            ->patchJson("/api/v1/admin/listings/{$listing->id}/approve")
            ->assertForbidden();
    }

    public function test_a_user_cannot_edit_someone_elses_listing(): void
    {
        $owner = User::factory()->create();
        $property = $this->createProperty($owner);
        $listing = PropertyListing::create([
            'property_id' => $property->id,
            'purpose' => 'rent',
            'price' => 20000,
            'price_period' => 'monthly',
            'title' => 'Someone elses listing',
            'slug' => 'someone-elses-listing',
            'status' => PropertyListing::STATUS_DRAFT,
            'created_by' => $owner->id,
        ]);

        $intruder = User::factory()->create();

        $this->actingAs($intruder, 'sanctum')
            ->putJson("/api/v1/owner/listings/{$listing->id}", ['title' => 'Hijacked'])
            ->assertForbidden();
    }
}
