<?php

namespace Tests\Feature\Engagement;

use App\Models\Municipality;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\Role;
use App\Models\SavedSearch;
use App\Models\User;
use App\Models\Ward;
use App\Notifications\SavedSearchMatchNotification;
use Database\Seeders\NepalLocationSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

/**
 * Saved-search CRUD already existed; the alert mechanism itself (this test
 * file) was the genuinely missing piece flagged by the competitive
 * benchmark — see PropertyListingService::approve() for the 'instant' hook
 * and SendSavedSearchDigests for the 'daily'/'weekly' cadences.
 */
class SavedSearchAlertTest extends TestCase
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
            'bedrooms' => 2,
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
            'title' => 'A matchable test listing',
            'slug' => 'a-matchable-test-listing-'.uniqid(),
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

    public function test_approving_a_listing_instantly_notifies_a_matching_saved_search(): void
    {
        Notification::fake();

        $buyer = User::factory()->create();
        $search = SavedSearch::create([
            'user_id' => $buyer->id,
            'name' => 'Rentals in Kathmandu',
            'filters' => ['purpose' => 'rent'],
            'alert_frequency' => 'instant',
        ]);

        $owner = User::factory()->create();
        $property = $this->createProperty($owner);
        $listing = $this->pendingListing($property, ['purpose' => 'rent']);

        $this->actingAs($this->admin(), 'sanctum')
            ->patchJson("/api/v1/admin/listings/{$listing->id}/approve")
            ->assertOk();

        Notification::assertSentTo($buyer, SavedSearchMatchNotification::class, function (SavedSearchMatchNotification $n) use ($listing) {
            return $n->listings[0]->id === $listing->id;
        });
        $this->assertNotNull($search->fresh()->last_notified_at);
    }

    public function test_a_non_matching_saved_search_is_not_notified(): void
    {
        Notification::fake();

        $buyer = User::factory()->create();
        SavedSearch::create([
            'user_id' => $buyer->id,
            'name' => 'Sales only',
            'filters' => ['purpose' => 'sale'],
            'alert_frequency' => 'instant',
        ]);

        $owner = User::factory()->create();
        $property = $this->createProperty($owner);
        $listing = $this->pendingListing($property, ['purpose' => 'rent']);

        $this->actingAs($this->admin(), 'sanctum')
            ->patchJson("/api/v1/admin/listings/{$listing->id}/approve")
            ->assertOk();

        Notification::assertNothingSentTo($buyer);
    }

    public function test_a_non_instant_saved_search_is_not_notified_inline(): void
    {
        Notification::fake();

        $buyer = User::factory()->create();
        SavedSearch::create([
            'user_id' => $buyer->id,
            'name' => 'Weekly digest only',
            'filters' => ['purpose' => 'rent'],
            'alert_frequency' => 'weekly',
        ]);

        $owner = User::factory()->create();
        $property = $this->createProperty($owner);
        $listing = $this->pendingListing($property, ['purpose' => 'rent']);

        $this->actingAs($this->admin(), 'sanctum')
            ->patchJson("/api/v1/admin/listings/{$listing->id}/approve")
            ->assertOk();

        // Not notified inline — that's the daily/weekly command's job.
        Notification::assertNothingSentTo($buyer);
    }

    public function test_the_daily_digest_command_notifies_a_due_matching_search_and_updates_the_watermark(): void
    {
        Notification::fake();

        $buyer = User::factory()->create();
        $search = SavedSearch::create([
            'user_id' => $buyer->id,
            'name' => 'Daily digest',
            'filters' => ['purpose' => 'rent'],
            'alert_frequency' => 'daily',
            'last_notified_at' => now()->subDays(2),
        ]);

        $owner = User::factory()->create();
        $property = $this->createProperty($owner);
        $listing = $this->pendingListing($property, ['purpose' => 'rent']);
        // Publish directly (bypassing approve(), which would already fire the
        // instant path) to isolate the digest command under test.
        $listing->update(['status' => PropertyListing::STATUS_PUBLISHED, 'published_at' => now()->subHours(2)]);

        Artisan::call('saved-searches:send-digests', ['frequency' => 'daily']);

        Notification::assertSentTo($buyer, SavedSearchMatchNotification::class, function (SavedSearchMatchNotification $n) use ($listing) {
            return count($n->listings) === 1 && $n->listings[0]->id === $listing->id;
        });
        $this->assertTrue($search->fresh()->last_notified_at->greaterThan(now()->subMinute()));
    }

    public function test_the_daily_digest_command_skips_a_search_not_yet_due(): void
    {
        Notification::fake();

        $buyer = User::factory()->create();
        SavedSearch::create([
            'user_id' => $buyer->id,
            'name' => 'Already notified recently',
            'filters' => ['purpose' => 'rent'],
            'alert_frequency' => 'daily',
            'last_notified_at' => now()->subHours(2),
        ]);

        $owner = User::factory()->create();
        $property = $this->createProperty($owner);
        $listing = $this->pendingListing($property, ['purpose' => 'rent']);
        $listing->update(['status' => PropertyListing::STATUS_PUBLISHED, 'published_at' => now()]);

        Artisan::call('saved-searches:send-digests', ['frequency' => 'daily']);

        Notification::assertNothingSentTo($buyer);
    }

    public function test_the_daily_digest_command_does_not_notify_when_there_are_no_new_matches(): void
    {
        Notification::fake();

        $buyer = User::factory()->create();
        $search = SavedSearch::create([
            'user_id' => $buyer->id,
            'name' => 'Nothing new',
            'filters' => ['purpose' => 'rent'],
            'alert_frequency' => 'daily',
            'last_notified_at' => now()->subDays(2),
        ]);

        Artisan::call('saved-searches:send-digests', ['frequency' => 'daily']);

        Notification::assertNothingSentTo($buyer);
        // Watermark still advances so a quiet period doesn't later dump a
        // huge backlog the moment a match finally appears.
        $this->assertTrue($search->fresh()->last_notified_at->greaterThan(now()->subMinute()));
    }
}
