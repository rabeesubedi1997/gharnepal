<?php

namespace Tests\Feature\Moderation;

use App\Models\Role;
use App\Models\User;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Feature\Engagement\CreatesListings;
use Tests\TestCase;

class ListingReportTest extends TestCase
{
    use RefreshDatabase, CreatesListings;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    public function test_a_user_can_report_a_listing(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);
        $reporter = User::factory()->create();

        $response = $this->actingAs($reporter, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/reports", [
            'reason' => 'misleading',
            'details' => 'Photos do not match the actual property.',
        ]);

        $response->assertCreated()->assertJsonPath('data.status', 'open');
        $this->assertDatabaseHas('listing_reports', ['property_listing_id' => $listing->id, 'reported_by' => $reporter->id]);
    }

    public function test_an_admin_can_resolve_a_report(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);
        $reporter = User::factory()->create();
        $admin = User::factory()->create();
        $admin->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']));

        $report = \App\Models\ListingReport::create([
            'property_listing_id' => $listing->id,
            'reported_by' => $reporter->id,
            'reason' => 'fraud',
        ]);

        $resolve = $this->actingAs($admin, 'sanctum')->patchJson("/api/v1/admin/reports/{$report->id}/resolve", [
            'status' => 'dismissed',
            'resolution_note' => 'Verified listing is legitimate.',
        ]);

        $resolve->assertOk()->assertJsonPath('data.status', 'dismissed');
    }

    public function test_a_non_admin_cannot_view_the_report_queue(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')->getJson('/api/v1/admin/reports')->assertForbidden();
    }

    public function test_guests_cannot_report_a_listing(): void
    {
        $owner = User::factory()->create();
        $listing = $this->publishedListing($owner);

        $this->postJson("/api/v1/listings/{$listing->id}/reports", ['reason' => 'fraud'])->assertUnauthorized();
    }
}
