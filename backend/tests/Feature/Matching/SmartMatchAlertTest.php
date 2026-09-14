<?php

namespace Tests\Feature\Matching;

use App\Domain\Matching\Services\SmartMatchAlertService;
use App\Models\MatchPreference;
use App\Models\Municipality;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\Role;
use App\Models\User;
use App\Models\Ward;
use App\Notifications\MatchThresholdNotification;
use Database\Seeders\NepalLocationSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

/**
 * Match results were previously only ever recomputed on preference-save or
 * a manual refresh — this is the missing "listing just published, does it
 * cross a buyer's 50% threshold" path. Mirrors
 * tests/Feature/Engagement/SavedSearchAlertTest.php's shape.
 */
class SmartMatchAlertTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed([RoleSeeder::class, NepalLocationSeeder::class]);
    }

    private function createProperty(User $owner, array $attrs = []): Property
    {
        $municipality = Municipality::where('code', 'M-KTM')->firstOrFail();
        $ward = Ward::where('municipality_id', $municipality->id)->first();

        $property = Property::create([
            'owner_user_id' => $owner->id,
            'created_by' => $owner->id,
            'property_type' => 'apartment',
            'total_area_sqm' => 100,
            'bedrooms' => 3,
            'bathrooms' => 1,
            ...$attrs,
        ]);

        $property->address()->create([
            'province_id' => $municipality->district->province_id,
            'district_id' => $municipality->district_id,
            'municipality_id' => $municipality->id,
            'ward_id' => $ward->id,
        ]);

        return $property;
    }

    private function pendingListing(Property $property, array $attrs = []): PropertyListing
    {
        return PropertyListing::create([
            'property_id' => $property->id,
            'purpose' => 'rent',
            'price' => 25000,
            'title' => 'A smart-matchable test listing',
            'slug' => 'a-smart-matchable-test-listing-'.uniqid(),
            'status' => PropertyListing::STATUS_PENDING_REVIEW,
            'created_by' => $property->owner_user_id,
            ...$attrs,
        ]);
    }

    private function admin(): User
    {
        $admin = User::factory()->create();
        $admin->roles()->attach(Role::where('key', Role::ADMIN)->first());

        return $admin;
    }

    public function test_approving_a_strongly_matching_listing_notifies_the_buyer(): void
    {
        Notification::fake();

        $buyer = User::factory()->create();
        MatchPreference::create([
            'user_id' => $buyer->id,
            'purposes' => ['rent'],
            'min_bedrooms' => 2,
        ]);

        $owner = User::factory()->create();
        $property = $this->createProperty($owner, ['bedrooms' => 3]);
        $listing = $this->pendingListing($property);

        $this->actingAs($this->admin(), 'sanctum')
            ->patchJson("/api/v1/admin/listings/{$listing->id}/approve")
            ->assertOk();

        Notification::assertSentTo($buyer, MatchThresholdNotification::class, function (MatchThresholdNotification $n) use ($listing) {
            return $n->listing->id === $listing->id && $n->score >= 50;
        });
        $this->assertDatabaseHas('match_results', [
            'user_id' => $buyer->id,
            'property_listing_id' => $listing->id,
        ]);
    }

    public function test_a_listing_outside_the_preferred_property_type_is_not_notified(): void
    {
        Notification::fake();

        $buyer = User::factory()->create();
        MatchPreference::create([
            'user_id' => $buyer->id,
            'property_types' => ['house'],
        ]);

        $owner = User::factory()->create();
        $property = $this->createProperty($owner, ['property_type' => 'apartment']);
        $listing = $this->pendingListing($property);

        $this->actingAs($this->admin(), 'sanctum')
            ->patchJson("/api/v1/admin/listings/{$listing->id}/approve")
            ->assertOk();

        Notification::assertNothingSentTo($buyer);
        $this->assertDatabaseMissing('match_results', ['user_id' => $buyer->id]);
    }

    public function test_a_buyer_with_multiple_purposes_selected_matches_either(): void
    {
        Notification::fake();

        $buyer = User::factory()->create();
        MatchPreference::create([
            'user_id' => $buyer->id,
            'purposes' => ['sale', 'rent'],
            'min_bedrooms' => 2,
        ]);

        $owner = User::factory()->create();
        $property = $this->createProperty($owner, ['bedrooms' => 3]);
        $listing = $this->pendingListing($property, ['purpose' => 'rent']);

        $this->actingAs($this->admin(), 'sanctum')
            ->patchJson("/api/v1/admin/listings/{$listing->id}/approve")
            ->assertOk();

        Notification::assertSentTo($buyer, MatchThresholdNotification::class);
    }

    public function test_a_listing_already_notified_at_or_above_threshold_is_not_notified_again(): void
    {
        Notification::fake();

        $buyer = User::factory()->create();
        $preference = MatchPreference::create([
            'user_id' => $buyer->id,
            'purposes' => ['rent'],
            'min_bedrooms' => 2,
        ]);

        $owner = User::factory()->create();
        $property = $this->createProperty($owner, ['bedrooms' => 3]);
        $listing = $this->pendingListing($property);
        $listing->update(['status' => PropertyListing::STATUS_PUBLISHED, 'published_at' => now()]);

        $service = app(SmartMatchAlertService::class);
        $service->notifyThresholdMatches($listing);
        $service->notifyThresholdMatches($listing);

        Notification::assertSentToTimes($buyer, MatchThresholdNotification::class, 1);
        $this->assertDatabaseCount('match_results', 1);
    }
}
