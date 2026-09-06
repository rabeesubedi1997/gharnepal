<?php

namespace Tests\Feature\Neighborhoods;

use App\Models\Municipality;
use App\Models\Neighborhood;
use App\Models\Role;
use App\Models\User;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NeighborhoodTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    private function ward(): Ward
    {
        $municipality = Municipality::where('code', 'M-KTM')->firstOrFail();

        return Ward::where('municipality_id', $municipality->id)->where('ward_number', 1)->firstOrFail();
    }

    private function admin(): User
    {
        $admin = User::factory()->create();
        $admin->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']));

        return $admin;
    }

    public function test_neighborhoods_are_listed_with_their_score_when_curated(): void
    {
        $neighborhood = Neighborhood::create(['ward_id' => $this->ward()->id, 'name' => 'Boudha']);

        $response = $this->getJson('/api/v1/neighborhoods');

        $response->assertOk();
        $names = collect($response->json('data'))->pluck('name');
        $this->assertTrue($names->contains('Boudha'));
    }

    public function test_a_neighborhood_profile_shows_score_pois_and_approved_notes_only(): void
    {
        $neighborhood = Neighborhood::create(['ward_id' => $this->ward()->id, 'name' => 'Boudha']);
        $admin = $this->admin();

        $this->actingAs($admin, 'sanctum')->postJson("/api/v1/admin/neighborhoods/{$neighborhood->id}/score", [
            'factors' => [
                ['key' => 'transport_access', 'score' => 8],
                ['key' => 'schools', 'score' => 6],
                ['key' => 'safety', 'score' => 7],
            ],
        ])->assertOk();

        $this->actingAs($admin, 'sanctum')->postJson("/api/v1/admin/neighborhoods/{$neighborhood->id}/pois", [
            'poi_type' => 'school',
            'name' => 'Boudha Secondary School',
        ])->assertCreated();

        $author = User::factory()->create(['phone_verified_at' => now()]);
        $note = $neighborhood->communityNotes()->create([
            'submitted_by' => $author->id,
            'category' => 'water_supply',
            'body' => 'Water supply is irregular in the dry season.',
            'status' => 'approved',
        ]);
        $neighborhood->communityNotes()->create([
            'submitted_by' => $author->id,
            'category' => 'noise',
            'body' => 'This one is still pending and must not show publicly.',
            'status' => 'pending',
        ]);

        $response = $this->getJson("/api/v1/neighborhoods/{$neighborhood->id}");

        $response->assertOk()
            ->assertJsonPath('data.score.overall_score', 7) // round(avg(8,6,7)) = 7
            ->assertJsonPath('data.pois.0.name', 'Boudha Secondary School')
            ->assertJsonCount(1, 'data.community_notes')
            ->assertJsonPath('data.community_notes.0.id', $note->id);

        $factorKeys = collect($response->json('data.score.factors'))->pluck('key');
        $this->assertEqualsCanonicalizing(['transport_access', 'schools', 'safety'], $factorKeys->all());
    }

    public function test_a_non_admin_cannot_set_a_neighborhood_score_or_add_a_poi(): void
    {
        $neighborhood = Neighborhood::create(['ward_id' => $this->ward()->id, 'name' => 'Boudha']);
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')->postJson("/api/v1/admin/neighborhoods/{$neighborhood->id}/score", [
            'factors' => [['key' => 'transport_access', 'score' => 8]],
        ])->assertForbidden();

        $this->actingAs($user, 'sanctum')->postJson("/api/v1/admin/neighborhoods/{$neighborhood->id}/pois", [
            'poi_type' => 'school', 'name' => 'Fake School',
        ])->assertForbidden();
    }

    public function test_an_admin_can_remove_a_poi(): void
    {
        $neighborhood = Neighborhood::create(['ward_id' => $this->ward()->id, 'name' => 'Boudha']);
        $admin = $this->admin();
        $poi = $neighborhood->pois()->create(['poi_type' => 'market', 'name' => 'Boudha Market', 'verified' => true]);

        $this->actingAs($admin, 'sanctum')->deleteJson("/api/v1/admin/neighborhood-pois/{$poi->id}")
            ->assertNoContent();

        $this->assertDatabaseMissing('neighborhood_pois', ['id' => $poi->id]);
    }

    public function test_setting_a_score_marks_the_neighborhood_as_curated(): void
    {
        $neighborhood = Neighborhood::create(['ward_id' => $this->ward()->id, 'name' => 'Chabahil', 'is_curated' => false]);
        $admin = $this->admin();

        $this->actingAs($admin, 'sanctum')->postJson("/api/v1/admin/neighborhoods/{$neighborhood->id}/score", [
            'factors' => [['key' => 'transport_access', 'score' => 7]],
        ])->assertOk()->assertJsonPath('data.is_curated', true);

        $this->assertTrue($neighborhood->fresh()->is_curated);
    }

    public function test_score_submission_rejects_an_unknown_factor_key(): void
    {
        $neighborhood = Neighborhood::create(['ward_id' => $this->ward()->id, 'name' => 'Boudha']);
        $admin = $this->admin();

        $this->actingAs($admin, 'sanctum')->postJson("/api/v1/admin/neighborhoods/{$neighborhood->id}/score", [
            'factors' => [['key' => 'not_a_real_factor', 'score' => 8]],
        ])->assertUnprocessable();
    }
}
