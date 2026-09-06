<?php

namespace Tests\Feature\Moderation;

use App\Models\Municipality;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\Role;
use App\Models\User;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DuplicateDetectionTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    private function listingInWard1(User $owner, float $price, float $areaSqm, string $title, string $status): PropertyListing
    {
        $municipality = Municipality::where('code', 'M-KTM')->firstOrFail();
        $ward = Ward::where('municipality_id', $municipality->id)->where('ward_number', 1)->firstOrFail();

        $property = Property::create([
            'owner_user_id' => $owner->id,
            'created_by' => $owner->id,
            'property_type' => 'apartment',
            'total_area_sqm' => $areaSqm,
            'bedrooms' => 2,
            'bathrooms' => 1,
        ]);
        $property->address()->create([
            'province_id' => $municipality->district->province_id,
            'district_id' => $municipality->district_id,
            'municipality_id' => $municipality->id,
            'ward_id' => $ward->id,
        ]);

        return PropertyListing::create([
            'property_id' => $property->id,
            'purpose' => 'rent',
            'price' => $price,
            'price_period' => 'monthly',
            'title' => $title,
            'slug' => str()->slug($title) . '-' . uniqid(),
            'status' => $status,
            'published_at' => $status === PropertyListing::STATUS_PUBLISHED ? now() : null,
            'created_by' => $owner->id,
        ]);
    }

    public function test_submitting_a_near_identical_listing_flags_it_as_a_possible_duplicate(): void
    {
        $owner = User::factory()->create();
        $this->listingInWard1($owner, 25000, 100, 'Cozy 2BHK apartment in Boudha', PropertyListing::STATUS_PUBLISHED);

        $draft = $this->listingInWard1($owner, 25500, 102, 'Cozy 2BHK apartment near Boudha', PropertyListing::STATUS_DRAFT);

        $this->actingAs($owner, 'sanctum')
            ->patchJson("/api/v1/owner/listings/{$draft->id}/transition", ['action' => 'submit'])
            ->assertOk();

        $this->assertDatabaseHas('duplicate_listing_flags', ['property_listing_id' => $draft->id]);

        $admin = User::factory()->create();
        $admin->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']));

        $queue = $this->actingAs($admin, 'sanctum')->getJson('/api/v1/admin/duplicate-flags');
        $queue->assertOk()->assertJsonCount(1, 'data');

        $flagId = $queue->json('data.0.id');
        $this->actingAs($admin, 'sanctum')
            ->patchJson("/api/v1/admin/duplicate-flags/{$flagId}/confirm")
            ->assertOk()->assertJsonPath('data.status', 'confirmed');
    }

    public function test_a_clearly_different_listing_is_not_flagged(): void
    {
        $owner = User::factory()->create();
        $this->listingInWard1($owner, 25000, 100, 'Cozy 2BHK apartment in Boudha', PropertyListing::STATUS_PUBLISHED);

        $draft = $this->listingInWard1($owner, 90000, 300, 'Large luxury villa with garden', PropertyListing::STATUS_DRAFT);

        $this->actingAs($owner, 'sanctum')
            ->patchJson("/api/v1/owner/listings/{$draft->id}/transition", ['action' => 'submit'])
            ->assertOk();

        $this->assertDatabaseMissing('duplicate_listing_flags', ['property_listing_id' => $draft->id]);
    }
}
