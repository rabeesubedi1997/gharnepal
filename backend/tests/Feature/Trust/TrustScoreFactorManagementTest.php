<?php

namespace Tests\Feature\Trust;

use App\Domain\Trust\Services\TrustScoreCalculator;
use App\Models\Municipality;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\Role;
use App\Models\TrustScoreFactor;
use App\Models\User;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Database\Seeders\TrustScoreFactorSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TrustScoreFactorManagementTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([NepalLocationSeeder::class, TrustScoreFactorSeeder::class]);
    }

    private function admin(): User
    {
        $admin = User::factory()->create();
        $admin->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']));

        return $admin;
    }

    private function publishedListing(User $owner): PropertyListing
    {
        $municipality = Municipality::where('code', 'M-KTM')->firstOrFail();
        $ward = Ward::where('municipality_id', $municipality->id)->where('ward_number', 1)->firstOrFail();

        $property = Property::create([
            'owner_user_id' => $owner->id, 'created_by' => $owner->id, 'property_type' => 'apartment', 'bedrooms' => 2, 'total_area_sqm' => 90,
        ]);
        $property->address()->create([
            'province_id' => $municipality->district->province_id, 'district_id' => $municipality->district_id,
            'municipality_id' => $municipality->id, 'ward_id' => $ward->id,
        ]);
        $property->managers()->attach($owner->id, ['relation' => 'owner']);

        return $property->listings()->create([
            'purpose' => 'rent', 'price' => 20000, 'price_period' => 'monthly',
            'title' => 'Trust factor test listing', 'slug' => 'trust-factor-test-'.uniqid(),
            'status' => PropertyListing::STATUS_PUBLISHED, 'published_at' => now(), 'created_by' => $owner->id,
        ]);
    }

    public function test_admin_can_list_trust_score_factors(): void
    {
        $admin = $this->admin();

        $response = $this->actingAs($admin, 'sanctum')->getJson('/api/v1/admin/trust-score-factors');

        $response->assertOk()->assertJsonCount(9, 'data');
    }

    public function test_deactivating_a_factor_stops_it_from_counting_toward_the_score(): void
    {
        $admin = $this->admin();
        $owner = User::factory()->create(['phone' => '9800000001', 'phone_verified_at' => now()]);
        $listing = $this->publishedListing($owner);

        app(TrustScoreCalculator::class)->recompute($listing);
        $before = $listing->fresh()->trustScore->total_score;

        $factor = TrustScoreFactor::where('key', TrustScoreFactor::PHONE_VERIFIED)->firstOrFail();
        $this->actingAs($admin, 'sanctum')->putJson("/api/v1/admin/trust-score-factors/{$factor->id}", [
            'is_active' => false,
        ])->assertOk()->assertJsonPath('data.is_active', false);

        app(TrustScoreCalculator::class)->recompute($listing);
        $after = $listing->fresh()->trustScore->total_score;

        $this->assertLessThan($before, $after);
    }

    public function test_max_points_can_be_edited(): void
    {
        $admin = $this->admin();
        $factor = TrustScoreFactor::where('key', TrustScoreFactor::PHONE_VERIFIED)->firstOrFail();

        $this->actingAs($admin, 'sanctum')->putJson("/api/v1/admin/trust-score-factors/{$factor->id}", [
            'max_points' => 25,
        ])->assertOk()->assertJsonPath('data.max_points', 25);
    }

    public function test_a_non_admin_cannot_manage_trust_score_factors(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')->getJson('/api/v1/admin/trust-score-factors')->assertForbidden();
    }
}
