<?php

namespace Tests\Feature\PropertyRequests;

use App\Models\Municipality;
use App\Models\PropertyRequest;
use App\Models\User;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PropertyRequestTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    public function test_a_user_can_post_a_property_request(): void
    {
        $user = User::factory()->create();
        $municipality = Municipality::where('code', 'M-KTM')->firstOrFail();

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/v1/property-requests', [
            'purpose' => 'rent',
            'property_type' => 'apartment',
            'budget_min' => 20000,
            'budget_max' => 35000,
            'bedrooms_min' => 2,
            'municipality_id' => $municipality->id,
            'notes' => 'Looking for something near a school, ground floor preferred.',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.purpose', 'rent')
            ->assertJsonPath('data.status', 'open')
            ->assertJsonPath('data.municipality', $municipality->name)
            ->assertJsonPath('data.posted_by', $user->name);
    }

    public function test_budget_max_cannot_be_below_budget_min(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')->postJson('/api/v1/property-requests', [
            'purpose' => 'sale',
            'budget_min' => 5000000,
            'budget_max' => 1000000,
        ])->assertUnprocessable();
    }

    public function test_guests_cannot_post_a_request(): void
    {
        $this->postJson('/api/v1/property-requests', ['purpose' => 'rent'])->assertUnauthorized();
    }

    public function test_the_public_list_only_shows_open_requests(): void
    {
        $user = User::factory()->create();
        $open = PropertyRequest::create(['user_id' => $user->id, 'purpose' => 'rent', 'status' => 'open']);
        $closed = PropertyRequest::create(['user_id' => $user->id, 'purpose' => 'rent', 'status' => 'closed']);

        $response = $this->getJson('/api/v1/property-requests');

        $response->assertOk();
        $ids = collect($response->json('data'))->pluck('id');
        $this->assertTrue($ids->contains($open->id));
        $this->assertFalse($ids->contains($closed->id));
    }

    public function test_the_owner_can_close_their_own_request(): void
    {
        $user = User::factory()->create();
        $request = PropertyRequest::create(['user_id' => $user->id, 'purpose' => 'sale', 'status' => 'open']);

        $this->actingAs($user, 'sanctum')->patchJson("/api/v1/property-requests/{$request->id}/close")
            ->assertOk()->assertJsonPath('data.status', 'closed');
    }

    public function test_a_different_user_cannot_close_someone_elses_request(): void
    {
        $owner = User::factory()->create();
        $request = PropertyRequest::create(['user_id' => $owner->id, 'purpose' => 'sale', 'status' => 'open']);
        $stranger = User::factory()->create();

        $this->actingAs($stranger, 'sanctum')->patchJson("/api/v1/property-requests/{$request->id}/close")
            ->assertForbidden();
    }

    public function test_my_requests_lists_own_requests_regardless_of_status(): void
    {
        $user = User::factory()->create();
        PropertyRequest::create(['user_id' => $user->id, 'purpose' => 'rent', 'status' => 'open']);
        PropertyRequest::create(['user_id' => $user->id, 'purpose' => 'sale', 'status' => 'closed']);
        $other = User::factory()->create();
        PropertyRequest::create(['user_id' => $other->id, 'purpose' => 'rent', 'status' => 'open']);

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/v1/account/property-requests');

        $response->assertOk()->assertJsonCount(2, 'data');
    }
}
