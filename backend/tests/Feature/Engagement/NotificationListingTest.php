<?php

namespace Tests\Feature\Engagement;

use App\Models\User;
use App\Notifications\ListingApprovedNotification;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NotificationListingTest extends TestCase
{
    use RefreshDatabase;
    use CreatesListings;

    public function test_a_users_notifications_are_returned_as_a_plain_array(): void
    {
        $this->seed(NepalLocationSeeder::class);
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);
        $owner->notify(new ListingApprovedNotification($listing));

        $response = $this->actingAs($owner, 'sanctum')->getJson('/api/v1/notifications');

        // Regression: the controller used to nest the paginator object
        // itself under 'data' (via ->through() without ->items()), so
        // 'data' was an object with its own current_page/data/... keys
        // instead of a plain array — this is exactly what broke on the
        // frontend as "data.map is not a function".
        $response->assertOk()->assertJsonCount(1, 'data');
        $this->assertIsArray($response->json('data'));
        $response->assertJsonPath('data.0.type', 'listing_approved');
        $response->assertJsonPath('meta.unread_count', 1);
    }

    public function test_a_notification_can_be_marked_read(): void
    {
        $this->seed(NepalLocationSeeder::class);
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);
        $owner->notify(new ListingApprovedNotification($listing));
        $notificationId = $owner->notifications()->first()->id;

        $response = $this->actingAs($owner, 'sanctum')
            ->patchJson("/api/v1/notifications/{$notificationId}/read");

        $response->assertOk();
        $this->assertNotNull($owner->notifications()->first()->read_at);
    }
}
