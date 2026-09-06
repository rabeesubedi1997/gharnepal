<?php

namespace Tests\Feature\Engagement;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SavedSearchTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_user_can_create_list_and_delete_a_saved_search(): void
    {
        $user = User::factory()->create();

        $create = $this->actingAs($user, 'sanctum')->postJson('/api/v1/account/saved-searches', [
            'name' => 'Rentals under 30k in Kathmandu',
            'filters' => ['purpose' => 'rent', 'max_price' => 30000, 'municipality_id' => 1],
        ]);
        $create->assertCreated()->assertJsonPath('data.name', 'Rentals under 30k in Kathmandu');
        $id = $create->json('data.id');

        $this->actingAs($user, 'sanctum')->getJson('/api/v1/account/saved-searches')
            ->assertOk()->assertJsonCount(1, 'data');

        $this->actingAs($user, 'sanctum')->deleteJson("/api/v1/account/saved-searches/{$id}")->assertNoContent();

        $this->assertDatabaseMissing('saved_searches', ['id' => $id]);
    }

    public function test_a_user_cannot_delete_someone_elses_saved_search(): void
    {
        $owner = User::factory()->create();
        $savedSearch = $owner->savedSearches()->create([
            'name' => 'Mine', 'filters' => ['purpose' => 'sale'], 'alert_frequency' => 'instant',
        ]);

        $intruder = User::factory()->create();

        $this->actingAs($intruder, 'sanctum')
            ->deleteJson("/api/v1/account/saved-searches/{$savedSearch->id}")
            ->assertForbidden();
    }
}
