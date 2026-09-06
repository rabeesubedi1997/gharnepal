<?php

namespace Tests\Feature\Trust;

use App\Models\Municipality;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\Role;
use App\Models\User;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Database\Seeders\TrustScoreFactorSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class TrustScoreTest extends TestCase
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

    /** Creates a property + listing and takes it all the way to published via the real API. */
    private function publishListing(User $owner): PropertyListing
    {
        $municipality = Municipality::where('code', 'M-KTM')->firstOrFail();
        $ward = Ward::where('municipality_id', $municipality->id)->where('ward_number', 1)->firstOrFail();

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

        $listing = PropertyListing::create([
            'property_id' => $property->id,
            'purpose' => 'rent',
            'price' => 20000,
            'price_period' => 'monthly',
            'title' => 'Trust score test listing',
            'slug' => 'trust-score-test-' . uniqid(),
            'status' => PropertyListing::STATUS_PENDING_REVIEW,
            'created_by' => $owner->id,
        ]);

        $this->actingAs($this->admin(), 'sanctum')
            ->patchJson("/api/v1/admin/listings/{$listing->id}/approve")
            ->assertOk();

        return $listing->fresh();
    }

    public function test_a_newly_published_listing_has_a_full_explainable_breakdown(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishListing($owner);

        $response = $this->getJson("/api/v1/listings/{$listing->slug}");

        $response->assertOk();
        $response->assertJsonPath('data.trust.score', fn ($score) => is_int($score) && $score >= 0 && $score <= 100);
        $this->assertGreaterThanOrEqual(9, count($response->json('data.trust.breakdown')));
        $this->assertDatabaseHas('listing_trust_scores', ['property_listing_id' => $listing->id]);
    }

    public function test_verifying_phone_increases_the_score_and_explanation(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishListing($owner);
        $before = $listing->trustScore->total_score;

        $capturedCode = null;
        Log::listen(function ($log) use (&$capturedCode) {
            if (preg_match('/OTP for .*: (\d+)/', $log->message, $m)) {
                $capturedCode = $m[1];
            }
        });

        $this->actingAs($owner, 'sanctum')->postJson('/api/v1/account/phone/request-otp', ['phone' => '9800000001'])->assertOk();
        $this->assertNotNull($capturedCode);

        $this->actingAs($owner, 'sanctum')->postJson('/api/v1/account/phone/verify-otp', [
            'phone' => '9800000001', 'code' => $capturedCode,
        ])->assertOk();

        $after = $listing->fresh()->trustScore->total_score;
        $this->assertGreaterThan($before, $after);

        $breakdown = collect($this->getJson("/api/v1/listings/{$listing->slug}")->json('data.trust.breakdown'));
        $phoneFactor = $breakdown->firstWhere('key', 'phone_verified');
        $this->assertEquals($phoneFactor['max_points'], $phoneFactor['points_awarded']);
    }

    public function test_a_confirmed_duplicate_flag_drops_the_no_duplicate_flags_factor(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishListing($owner);
        $otherListing = $this->publishListing(User::factory()->create());

        \App\Models\DuplicateListingFlag::create([
            'property_listing_id' => $listing->id,
            'duplicate_of_listing_id' => $otherListing->id,
            'match_score' => 90,
            'match_reasons' => ['similar_title'],
            'status' => 'unreviewed',
        ]);

        $admin = $this->admin();
        $flagId = \App\Models\DuplicateListingFlag::where('property_listing_id', $listing->id)->first()->id;

        $this->actingAs($admin, 'sanctum')->patchJson("/api/v1/admin/duplicate-flags/{$flagId}/confirm")->assertOk();

        $breakdown = collect($this->getJson("/api/v1/listings/{$listing->slug}")->json('data.trust.breakdown'));
        $factor = $breakdown->firstWhere('key', 'no_duplicate_flags');
        $this->assertEquals(0, $factor['points_awarded']);
    }

    public function test_an_admin_can_override_the_score_and_clear_the_override(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishListing($owner);
        $admin = $this->admin();

        $override = $this->actingAs($admin, 'sanctum')->postJson("/api/v1/admin/listings/{$listing->id}/trust-override", [
            'override_score' => 5,
            'note' => 'Manual review found serious concerns.',
        ]);
        $override->assertOk()->assertJsonPath('data.score', 5)->assertJsonPath('data.is_overridden', true);

        $clear = $this->actingAs($admin, 'sanctum')->deleteJson("/api/v1/admin/listings/{$listing->id}/trust-override");
        $clear->assertOk()->assertJsonPath('data.is_overridden', false);
    }
}
