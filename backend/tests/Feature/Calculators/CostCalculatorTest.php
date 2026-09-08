<?php

namespace Tests\Feature\Calculators;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CostCalculatorTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_guest_can_compute_a_rental_cost_estimate_without_saving(): void
    {
        $response = $this->postJson('/api/v1/calculators/rental', [
            'monthly_rent' => 25000,
            'deposit_months' => 2,
            'utilities_monthly' => 1500,
            'brokerage_fee' => 5000,
        ]);

        $response->assertOk();
        $this->assertEquals(50000, $response->json('data.result.breakdown.deposit'));
        $this->assertEquals(26500, $response->json('data.result.monthly_recurring_total'));
        $this->assertNull($response->json('data.scenario'));
        $this->assertDatabaseCount('cost_calculator_scenarios', 0);
    }

    public function test_a_logged_in_user_can_save_a_purchase_scenario(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/v1/calculators/purchase', [
            'property_price' => 10000000,
            'down_payment_percent' => 20,
            'loan_interest_rate_annual' => 10,
            'loan_tenure_years' => 20,
            'monthly_rent_estimate' => 40000,
            'save' => true,
            'name' => 'My dream house',
        ]);

        $response->assertOk();
        $this->assertEquals(2000000, $response->json('data.result.breakdown.down_payment'));
        $this->assertEquals(4.8, $response->json('data.result.rental_yield_percent'));
        $this->assertNotNull($response->json('data.scenario.id'));
        $this->assertDatabaseHas('cost_calculator_scenarios', ['user_id' => $user->id, 'name' => 'My dream house']);
    }

    public function test_a_bearer_token_client_can_save_a_scenario(): void
    {
        // Deliberately not actingAs(): that helper calls Auth::shouldUse()
        // itself, which would mask the real bug — this route carries no
        // auth:sanctum middleware (saving is opt-in, not a requirement), so
        // nothing switches the request's default guard for a real HTTP
        // request. A genuine bearer-token request is the only way to catch it.
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer {$token}")->postJson('/api/v1/calculators/rental', [
            'monthly_rent' => 18000,
            'save' => true,
            'name' => 'Bearer client scenario',
        ]);

        $response->assertOk();
        $this->assertNotNull($response->json('data.scenario.id'), 'save=true should persist a scenario for a bearer-token client too');
        $this->assertDatabaseHas('cost_calculator_scenarios', ['user_id' => $user->id, 'name' => 'Bearer client scenario']);
    }

    public function test_a_user_can_list_and_delete_their_saved_scenarios(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user, 'sanctum')->postJson('/api/v1/calculators/rental', [
            'monthly_rent' => 15000, 'save' => true, 'name' => 'Studio near office',
        ]);

        $list = $this->actingAs($user, 'sanctum')->getJson('/api/v1/account/calculator-scenarios');
        $list->assertOk()->assertJsonCount(1, 'data');

        $id = $list->json('data.0.id');
        $this->actingAs($user, 'sanctum')->deleteJson("/api/v1/account/calculator-scenarios/{$id}")->assertNoContent();
        $this->assertDatabaseMissing('cost_calculator_scenarios', ['id' => $id]);
    }

    public function test_a_user_cannot_delete_someone_elses_scenario(): void
    {
        $owner = User::factory()->create();
        $scenario = $owner->calculatorScenarios()->create([
            'type' => 'rental', 'inputs' => [], 'computed_result' => [],
        ]);

        $intruder = User::factory()->create();
        $this->actingAs($intruder, 'sanctum')
            ->deleteJson("/api/v1/account/calculator-scenarios/{$scenario->id}")
            ->assertForbidden();
    }
}
