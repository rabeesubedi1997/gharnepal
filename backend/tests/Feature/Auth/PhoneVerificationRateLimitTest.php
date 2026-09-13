<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PhoneVerificationRateLimitTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_second_otp_request_within_the_cooldown_is_rate_limited(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/account/phone/request-otp', ['phone' => '9800000000'])
            ->assertOk();

        // The 'otp-request' limiter allows 1 request per 30s per account —
        // this is the actual cooldown fix, not just generic throttling.
        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/account/phone/request-otp', ['phone' => '9800000000'])
            ->assertStatus(429);
    }

    public function test_different_users_each_get_their_own_otp_request_cooldown(): void
    {
        $first = User::factory()->create();
        $second = User::factory()->create();

        $this->actingAs($first, 'sanctum')
            ->postJson('/api/v1/account/phone/request-otp', ['phone' => '9800000001'])
            ->assertOk();

        // A different account isn't blocked by the first account's cooldown.
        $this->actingAs($second, 'sanctum')
            ->postJson('/api/v1/account/phone/request-otp', ['phone' => '9800000002'])
            ->assertOk();
    }
}
