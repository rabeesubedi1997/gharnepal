<?php

namespace Tests\Feature\Agency;

use App\Models\Agency;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\Municipality;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\User;
use App\Models\ViewingRequest;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Every figure this dashboard shows must be a real, independently-checkable
 * query result — these tests assert the actual computed numbers, not just
 * that the endpoint returns 200.
 */
class AgencyDashboardTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    private function listingFor(User $agent, array $overrides = []): PropertyListing
    {
        $municipality = Municipality::where('code', 'M-KTM')->firstOrFail();
        $ward = Ward::where('municipality_id', $municipality->id)->where('ward_number', 1)->firstOrFail();

        $property = Property::create([
            'owner_user_id' => $agent->id,
            'created_by' => $agent->id,
            'property_type' => 'house',
            'bedrooms' => 3,
            'total_area_sqm' => 150,
        ]);
        $property->address()->create([
            'province_id' => $municipality->district->province_id,
            'district_id' => $municipality->district_id,
            'municipality_id' => $municipality->id,
            'ward_id' => $ward->id,
        ]);

        return $property->listings()->create(array_merge([
            'purpose' => 'sale',
            'price' => 10_000_000,
            'title' => 'Agency dashboard test listing ' . uniqid(),
            'slug' => 'agency-dashboard-test-' . uniqid(),
            'status' => PropertyListing::STATUS_PUBLISHED,
            'published_at' => now(),
            'created_by' => $agent->id,
        ], $overrides));
    }

    public function test_a_non_agency_member_gets_a_404_from_every_dashboard_endpoint(): void
    {
        $user = User::factory()->create();

        foreach (['overview', 'listings', 'inquiries', 'site-visits'] as $endpoint) {
            $this->actingAs($user, 'sanctum')
                ->getJson("/api/v1/agency/dashboard/{$endpoint}")
                ->assertNotFound();
        }
    }

    public function test_overview_reports_real_portfolio_value_and_response_rate(): void
    {
        $agent = User::factory()->create();
        $agency = Agency::create(['name' => 'Test Realty', 'slug' => 'test-realty', 'status' => 'active', 'verified_at' => now()]);
        $agency->members()->attach($agent->id, ['role_in_agency' => 'owner_admin']);

        $listingA = $this->listingFor($agent, ['price' => 10_000_000, 'purpose' => 'sale']);
        $this->listingFor($agent, ['price' => 25_000_000, 'purpose' => 'sale']);
        // A rental listing's monthly price must never be summed into the
        // sale-portfolio total — that would silently corrupt the figure.
        $this->listingFor($agent, ['price' => 30_000, 'purpose' => 'rent', 'price_period' => 'monthly']);

        $buyerReplied = User::factory()->create();
        $convo1 = Conversation::create(['property_listing_id' => $listingA->id, 'buyer_user_id' => $buyerReplied->id, 'owner_user_id' => $agent->id, 'status' => 'open', 'last_message_at' => now()]);
        Message::create(['conversation_id' => $convo1->id, 'sender_user_id' => $buyerReplied->id, 'body' => 'Interested!']);
        Message::create(['conversation_id' => $convo1->id, 'sender_user_id' => $agent->id, 'body' => 'Thanks, happy to help.']);

        $buyerIgnored = User::factory()->create();
        $convo2 = Conversation::create(['property_listing_id' => $listingA->id, 'buyer_user_id' => $buyerIgnored->id, 'owner_user_id' => $agent->id, 'status' => 'open', 'last_message_at' => now()]);
        Message::create(['conversation_id' => $convo2->id, 'sender_user_id' => $buyerIgnored->id, 'body' => 'Still available?']);

        $response = $this->actingAs($agent, 'sanctum')->getJson('/api/v1/agency/dashboard/overview');

        $response->assertOk()
            ->assertJsonPath('data.agency.name', 'Test Realty')
            ->assertJsonPath('data.portfolio.active_count', 3)
            ->assertJsonPath('data.inquiries_30d.count', 2)
            ->assertJsonPath('data.inquiries_30d.response_rate_pct', 50)
            ->assertJsonPath('data.for_sale_portfolio_value.total', 35_000_000)
            ->assertJsonPath('data.for_sale_portfolio_value.listing_count', 2);
    }

    public function test_site_visits_only_counts_upcoming_ones_within_the_next_7_days(): void
    {
        $agent = User::factory()->create();
        $agency = Agency::create(['name' => 'Test Realty', 'slug' => 'test-realty-2', 'status' => 'active', 'verified_at' => now()]);
        $agency->members()->attach($agent->id, ['role_in_agency' => 'owner_admin']);

        $listing = $this->listingFor($agent);
        $requester = User::factory()->create();

        ViewingRequest::create([
            'property_listing_id' => $listing->id,
            'requester_user_id' => $requester->id,
            'host_user_id' => $agent->id,
            'proposed_datetime' => now()->addDays(3),
            'status' => ViewingRequest::STATUS_REQUESTED,
        ]);
        // Outside the 7-day window — must not count.
        ViewingRequest::create([
            'property_listing_id' => $listing->id,
            'requester_user_id' => $requester->id,
            'host_user_id' => $agent->id,
            'proposed_datetime' => now()->addDays(30),
            'status' => ViewingRequest::STATUS_REQUESTED,
        ]);
        // Already completed — must not count as upcoming.
        ViewingRequest::create([
            'property_listing_id' => $listing->id,
            'requester_user_id' => $requester->id,
            'host_user_id' => $agent->id,
            'proposed_datetime' => now()->subDays(2),
            'confirmed_datetime' => now()->subDays(2),
            'status' => ViewingRequest::STATUS_COMPLETED,
        ]);

        $response = $this->actingAs($agent, 'sanctum')->getJson('/api/v1/agency/dashboard/overview');

        $response->assertOk()->assertJsonPath('data.site_visits.upcoming_7d', 1);

        $list = $this->actingAs($agent, 'sanctum')->getJson('/api/v1/agency/dashboard/site-visits');
        $list->assertOk()->assertJsonCount(1, 'data');
    }

    public function test_listings_endpoint_filters_by_category_and_reports_real_engagement_counts(): void
    {
        $agent = User::factory()->create();
        $agency = Agency::create(['name' => 'Test Realty', 'slug' => 'test-realty-3', 'status' => 'active', 'verified_at' => now()]);
        $agency->members()->attach($agent->id, ['role_in_agency' => 'owner_admin']);

        $house = $this->listingFor($agent);
        $requester = User::factory()->create();
        Conversation::create(['property_listing_id' => $house->id, 'buyer_user_id' => $requester->id, 'owner_user_id' => $agent->id, 'status' => 'open', 'last_message_at' => now()]);
        ViewingRequest::create(['property_listing_id' => $house->id, 'requester_user_id' => $requester->id, 'host_user_id' => $agent->id, 'proposed_datetime' => now()->addDay(), 'status' => ViewingRequest::STATUS_REQUESTED]);

        $response = $this->actingAs($agent, 'sanctum')->getJson('/api/v1/agency/dashboard/listings?category=houses');

        $response->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.inquiries_count', 1)
            ->assertJsonPath('data.0.leads_count', 1);

        $this->actingAs($agent, 'sanctum')
            ->getJson('/api/v1/agency/dashboard/listings?category=land')
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }

    public function test_a_listing_owned_by_a_different_agencys_member_never_appears(): void
    {
        $agentA = User::factory()->create();
        $agencyA = Agency::create(['name' => 'Agency A', 'slug' => 'agency-a', 'status' => 'active', 'verified_at' => now()]);
        $agencyA->members()->attach($agentA->id, ['role_in_agency' => 'owner_admin']);

        $agentB = User::factory()->create();
        Agency::create(['name' => 'Agency B', 'slug' => 'agency-b', 'status' => 'active', 'verified_at' => now()])
            ->members()->attach($agentB->id, ['role_in_agency' => 'owner_admin']);
        $this->listingFor($agentB);

        $response = $this->actingAs($agentA, 'sanctum')->getJson('/api/v1/agency/dashboard/overview');

        $response->assertOk()->assertJsonPath('data.portfolio.active_count', 0);
    }
}
