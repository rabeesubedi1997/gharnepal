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

class CommunityNoteTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    private function neighborhood(): Neighborhood
    {
        $municipality = Municipality::where('code', 'M-KTM')->firstOrFail();
        $ward = Ward::where('municipality_id', $municipality->id)->where('ward_number', 1)->firstOrFail();

        return Neighborhood::create(['ward_id' => $ward->id, 'name' => 'Boudha']);
    }

    private function admin(): User
    {
        $admin = User::factory()->create();
        $admin->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']));

        return $admin;
    }

    public function test_a_phone_verified_user_can_submit_a_community_note(): void
    {
        $neighborhood = $this->neighborhood();
        $user = User::factory()->create(['phone_verified_at' => now()]);

        $response = $this->actingAs($user, 'sanctum')->postJson("/api/v1/neighborhoods/{$neighborhood->id}/community-notes", [
            'category' => 'water_supply',
            'body' => 'Water supply cuts out most evenings in the dry season.',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.category', 'water_supply')
            ->assertJsonPath('data.status', 'pending');

        $this->assertDatabaseHas('community_notes', [
            'neighborhood_id' => $neighborhood->id,
            'submitted_by' => $user->id,
            'status' => 'pending',
        ]);
    }

    public function test_an_unverified_user_cannot_submit_a_community_note(): void
    {
        $neighborhood = $this->neighborhood();
        $user = User::factory()->create(['phone_verified_at' => null]);

        $this->actingAs($user, 'sanctum')->postJson("/api/v1/neighborhoods/{$neighborhood->id}/community-notes", [
            'category' => 'noise',
            'body' => 'Loud construction every morning.',
        ])->assertUnprocessable();
    }

    public function test_guests_cannot_submit_a_community_note(): void
    {
        $neighborhood = $this->neighborhood();

        $this->postJson("/api/v1/neighborhoods/{$neighborhood->id}/community-notes", [
            'category' => 'noise',
            'body' => 'Loud construction every morning.',
        ])->assertUnauthorized();
    }

    public function test_a_note_longer_than_500_characters_is_rejected(): void
    {
        $neighborhood = $this->neighborhood();
        $user = User::factory()->create(['phone_verified_at' => now()]);

        $this->actingAs($user, 'sanctum')->postJson("/api/v1/neighborhoods/{$neighborhood->id}/community-notes", [
            'category' => 'other',
            'body' => str_repeat('a', 501),
        ])->assertUnprocessable();
    }

    public function test_an_admin_can_approve_a_pending_note_and_it_becomes_publicly_visible(): void
    {
        $neighborhood = $this->neighborhood();
        $author = User::factory()->create(['phone_verified_at' => now()]);
        $note = $neighborhood->communityNotes()->create([
            'submitted_by' => $author->id,
            'category' => 'road_condition',
            'body' => 'Main road is pitted after monsoon.',
            'status' => 'pending',
        ]);
        $admin = $this->admin();

        $this->actingAs($admin, 'sanctum')->patchJson("/api/v1/admin/community-notes/{$note->id}/approve")
            ->assertOk()
            ->assertJsonPath('data.status', 'approved');

        $this->getJson("/api/v1/neighborhoods/{$neighborhood->id}")
            ->assertJsonCount(1, 'data.community_notes');
    }

    public function test_an_admin_can_reject_a_note_with_a_reason(): void
    {
        $neighborhood = $this->neighborhood();
        $author = User::factory()->create(['phone_verified_at' => now()]);
        $note = $neighborhood->communityNotes()->create([
            'submitted_by' => $author->id,
            'category' => 'other',
            'body' => 'Spam-ish content.',
            'status' => 'pending',
        ]);
        $admin = $this->admin();

        $this->actingAs($admin, 'sanctum')->patchJson("/api/v1/admin/community-notes/{$note->id}/reject", [
            'reason' => 'Not neighborhood-related.',
        ])->assertOk()
            ->assertJsonPath('data.status', 'rejected')
            ->assertJsonPath('data.rejection_reason', 'Not neighborhood-related.');
    }

    public function test_a_non_admin_cannot_view_or_moderate_the_note_queue(): void
    {
        $neighborhood = $this->neighborhood();
        $author = User::factory()->create(['phone_verified_at' => now()]);
        $note = $neighborhood->communityNotes()->create([
            'submitted_by' => $author->id,
            'category' => 'other',
            'body' => 'Some note.',
            'status' => 'pending',
        ]);
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')->getJson('/api/v1/admin/community-notes')->assertForbidden();
        $this->actingAs($user, 'sanctum')->patchJson("/api/v1/admin/community-notes/{$note->id}/approve")->assertForbidden();
    }

    public function test_the_note_submitter_is_only_exposed_to_admins(): void
    {
        $neighborhood = $this->neighborhood();
        $author = User::factory()->create(['phone_verified_at' => now(), 'name' => 'Anita Shrestha']);
        $neighborhood->communityNotes()->create([
            'submitted_by' => $author->id,
            'category' => 'other',
            'body' => 'Some public note.',
            'status' => 'approved',
        ]);

        $response = $this->getJson("/api/v1/neighborhoods/{$neighborhood->id}");

        $response->assertOk()->assertJsonMissingPath('data.community_notes.0.submitted_by');
    }
}
