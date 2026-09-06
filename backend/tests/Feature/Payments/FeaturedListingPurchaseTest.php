<?php

namespace Tests\Feature\Payments;

use App\Models\Municipality;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\Role;
use App\Models\User;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FeaturedListingPurchaseTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    /** @return array{0: PropertyListing, 1: User} */
    private function publishedListing(array $listingOverrides = []): array
    {
        $owner = User::factory()->create();
        $municipality = Municipality::where('code', 'M-KTM')->firstOrFail();
        $ward = Ward::where('municipality_id', $municipality->id)->where('ward_number', 1)->firstOrFail();

        $property = Property::create([
            'owner_user_id' => $owner->id,
            'created_by' => $owner->id,
            'property_type' => 'apartment',
            'bedrooms' => 2,
            'bathrooms' => 1,
            'total_area_sqm' => 80,
        ]);
        $property->address()->create([
            'province_id' => $municipality->district->province_id,
            'district_id' => $municipality->district_id,
            'municipality_id' => $municipality->id,
            'ward_id' => $ward->id,
        ]);
        $property->managers()->attach($owner->id, ['relation' => 'owner']);

        $listing = $property->listings()->create(array_merge([
            'purpose' => 'rent',
            'price' => 25000,
            'price_period' => 'monthly',
            'title' => 'Boosted listing test',
            'slug' => 'boosted-listing-test-' . uniqid(),
            'status' => PropertyListing::STATUS_PUBLISHED,
            'published_at' => now(),
            'created_by' => $owner->id,
        ], $listingOverrides));

        return [$listing, $owner];
    }

    public function test_the_plan_catalog_is_public(): void
    {
        $this->getJson('/api/v1/featured-plans')
            ->assertOk()
            ->assertJsonCount(3, 'data')
            ->assertJsonPath('data.0.key', 'boost_7');
    }

    public function test_owner_can_initiate_a_boost_purchase(): void
    {
        [$listing, $owner] = $this->publishedListing();

        $response = $this->actingAs($owner, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/feature", [
            'plan_key' => 'boost_7',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.status', 'pending')
            ->assertJsonPath('data.plan_days', 7)
            ->assertJsonPath('data.amount', 500);

        $this->assertDatabaseHas('payment_transactions', [
            'property_listing_id' => $listing->id,
            'user_id' => $owner->id,
            'status' => 'pending',
        ]);
    }

    public function test_a_non_manager_cannot_purchase_a_boost_for_someone_elses_listing(): void
    {
        [$listing] = $this->publishedListing();
        $intruder = User::factory()->create();

        $this->actingAs($intruder, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/feature", [
            'plan_key' => 'boost_7',
        ])->assertForbidden();
    }

    public function test_guests_cannot_purchase_a_boost(): void
    {
        [$listing] = $this->publishedListing();

        $this->postJson("/api/v1/listings/{$listing->id}/feature", ['plan_key' => 'boost_7'])
            ->assertUnauthorized();
    }

    public function test_an_unknown_plan_key_is_rejected(): void
    {
        [$listing, $owner] = $this->publishedListing();

        $this->actingAs($owner, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/feature", [
            'plan_key' => 'not_a_real_plan',
        ])->assertUnprocessable();
    }

    public function test_confirming_success_activates_the_boost_and_completes_the_transaction(): void
    {
        [$listing, $owner] = $this->publishedListing();

        $create = $this->actingAs($owner, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/feature", [
            'plan_key' => 'boost_15',
        ]);
        $transactionId = $create->json('data.id');

        $response = $this->actingAs($owner, 'sanctum')->postJson("/api/v1/account/payments/{$transactionId}/confirm", [
            'outcome' => 'success',
        ]);

        $response->assertOk()
            ->assertJsonPath('data.status', 'completed')
            ->assertJsonPath('data.listing.featured_until', fn ($v) => $v !== null);

        $listing->refresh();
        $this->assertTrue($listing->isFeatured());
        $this->assertTrue($listing->featured_until->isBetween(now()->addDays(14), now()->addDays(16)));
    }

    public function test_confirming_failure_leaves_the_listing_unfeatured(): void
    {
        [$listing, $owner] = $this->publishedListing();

        $create = $this->actingAs($owner, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/feature", [
            'plan_key' => 'boost_7',
        ]);
        $transactionId = $create->json('data.id');

        $this->actingAs($owner, 'sanctum')->postJson("/api/v1/account/payments/{$transactionId}/confirm", [
            'outcome' => 'failure',
        ])->assertOk()->assertJsonPath('data.status', 'failed');

        $this->assertFalse($listing->fresh()->isFeatured());
    }

    public function test_a_transaction_cannot_be_confirmed_twice(): void
    {
        [$listing, $owner] = $this->publishedListing();

        $create = $this->actingAs($owner, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/feature", [
            'plan_key' => 'boost_7',
        ]);
        $transactionId = $create->json('data.id');

        $this->actingAs($owner, 'sanctum')->postJson("/api/v1/account/payments/{$transactionId}/confirm", ['outcome' => 'success'])
            ->assertOk();

        $this->actingAs($owner, 'sanctum')->postJson("/api/v1/account/payments/{$transactionId}/confirm", ['outcome' => 'success'])
            ->assertUnprocessable();
    }

    public function test_another_user_cannot_confirm_someone_elses_transaction(): void
    {
        [$listing, $owner] = $this->publishedListing();
        $intruder = User::factory()->create();

        $create = $this->actingAs($owner, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/feature", [
            'plan_key' => 'boost_7',
        ]);
        $transactionId = $create->json('data.id');

        $this->actingAs($intruder, 'sanctum')->postJson("/api/v1/account/payments/{$transactionId}/confirm", [
            'outcome' => 'success',
        ])->assertForbidden();
    }

    public function test_a_second_successful_boost_extends_from_the_current_featured_until_not_from_now(): void
    {
        [$listing, $owner] = $this->publishedListing(['featured_until' => now()->addDays(5)]);

        $create = $this->actingAs($owner, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/feature", [
            'plan_key' => 'boost_7',
        ]);
        $transactionId = $create->json('data.id');

        $this->actingAs($owner, 'sanctum')->postJson("/api/v1/account/payments/{$transactionId}/confirm", ['outcome' => 'success'])
            ->assertOk();

        // 5 days already remaining + 7 new days = ~12 days out, not 7.
        $this->assertTrue($listing->fresh()->featured_until->isBetween(now()->addDays(11), now()->addDays(13)));
    }

    public function test_owner_can_view_their_own_payment_history(): void
    {
        [$listing, $owner] = $this->publishedListing();
        $this->actingAs($owner, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/feature", ['plan_key' => 'boost_7']);

        $this->actingAs($owner, 'sanctum')->getJson('/api/v1/account/payments')
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    public function test_an_admin_can_view_all_transactions_but_a_non_admin_cannot(): void
    {
        [$listing, $owner] = $this->publishedListing();
        $this->actingAs($owner, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/feature", ['plan_key' => 'boost_7']);

        $admin = User::factory()->create();
        $admin->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']));

        $this->actingAs($admin, 'sanctum')->getJson('/api/v1/admin/payments')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.user.id', $owner->id);

        $this->actingAs($owner, 'sanctum')->getJson('/api/v1/admin/payments')->assertForbidden();
    }

    public function test_admin_payments_can_be_filtered_by_status(): void
    {
        [$listing, $owner] = $this->publishedListing();
        $create = $this->actingAs($owner, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/feature", ['plan_key' => 'boost_7']);
        $this->actingAs($owner, 'sanctum')->postJson("/api/v1/account/payments/{$create->json('data.id')}/confirm", ['outcome' => 'success']);

        [$listing2, $owner2] = $this->publishedListing();
        $this->actingAs($owner2, 'sanctum')->postJson("/api/v1/listings/{$listing2->id}/feature", ['plan_key' => 'boost_7']);

        $admin = User::factory()->create();
        $admin->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']));

        $this->actingAs($admin, 'sanctum')->getJson('/api/v1/admin/payments?status=completed')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.status', 'completed');
    }

    public function test_admin_can_refund_a_completed_payment(): void
    {
        [$listing, $owner] = $this->publishedListing();
        $create = $this->actingAs($owner, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/feature", ['plan_key' => 'boost_7']);
        $transactionId = $create->json('data.id');
        $this->actingAs($owner, 'sanctum')->postJson("/api/v1/account/payments/{$transactionId}/confirm", ['outcome' => 'success']);

        $admin = User::factory()->create();
        $admin->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']));

        $this->actingAs($admin, 'sanctum')->patchJson("/api/v1/admin/payments/{$transactionId}/refund")
            ->assertOk()
            ->assertJsonPath('data.status', 'refunded');

        $this->assertDatabaseHas('payment_transactions', ['id' => $transactionId, 'status' => 'refunded']);
    }

    public function test_a_pending_payment_cannot_be_refunded(): void
    {
        [$listing, $owner] = $this->publishedListing();
        $create = $this->actingAs($owner, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/feature", ['plan_key' => 'boost_7']);
        $transactionId = $create->json('data.id');

        $admin = User::factory()->create();
        $admin->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']));

        $this->actingAs($admin, 'sanctum')->patchJson("/api/v1/admin/payments/{$transactionId}/refund")
            ->assertUnprocessable();
    }

    public function test_a_non_admin_cannot_refund_a_payment(): void
    {
        [$listing, $owner] = $this->publishedListing();
        $create = $this->actingAs($owner, 'sanctum')->postJson("/api/v1/listings/{$listing->id}/feature", ['plan_key' => 'boost_7']);
        $transactionId = $create->json('data.id');

        $this->actingAs($owner, 'sanctum')->patchJson("/api/v1/admin/payments/{$transactionId}/refund")
            ->assertForbidden();
    }
}
