<?php

namespace Tests\Feature\Moderation;

use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class VerificationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    public function test_a_user_can_submit_an_identity_verification_document(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/v1/account/verifications', [
            'type' => 'identity',
            'document' => UploadedFile::fake()->image('citizenship.jpg'),
        ]);

        $response->assertCreated()->assertJsonPath('data.status', 'pending');
        $this->assertDatabaseHas('user_verifications', ['user_id' => $user->id, 'type' => 'identity', 'status' => 'pending']);
        $this->assertFalse($user->fresh()->isVerified());
    }

    public function test_an_admin_can_approve_a_verification(): void
    {
        $user = User::factory()->create();
        $admin = User::factory()->create();
        $admin->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']));

        $submit = $this->actingAs($user, 'sanctum')->postJson('/api/v1/account/verifications', [
            'type' => 'identity',
            'document' => UploadedFile::fake()->image('citizenship.jpg'),
        ]);
        $id = $submit->json('data.id');

        $approve = $this->actingAs($admin, 'sanctum')->patchJson("/api/v1/admin/verifications/{$id}/approve");
        $approve->assertOk()->assertJsonPath('data.status', 'approved');

        $this->assertTrue($user->fresh()->isVerified());
    }

    public function test_an_admin_can_reject_a_verification_with_a_reason(): void
    {
        $user = User::factory()->create();
        $admin = User::factory()->create();
        $admin->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Administrator']));

        $submit = $this->actingAs($user, 'sanctum')->postJson('/api/v1/account/verifications', [
            'type' => 'identity',
            'document' => UploadedFile::fake()->image('blurry.jpg'),
        ]);
        $id = $submit->json('data.id');

        $reject = $this->actingAs($admin, 'sanctum')->patchJson("/api/v1/admin/verifications/{$id}/reject", [
            'reason' => 'Document image is unreadable, please resubmit.',
        ]);
        $reject->assertOk()->assertJsonPath('data.status', 'rejected');
    }
}
