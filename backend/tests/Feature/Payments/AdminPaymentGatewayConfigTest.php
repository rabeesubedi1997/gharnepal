<?php

namespace Tests\Feature\Payments;

use App\Models\PaymentGatewayConfig;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminPaymentGatewayConfigTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        $user = User::factory()->create();
        $user->roles()->attach(Role::firstOrCreate(['key' => Role::ADMIN], ['name' => 'Admin']));

        return $user;
    }

    public function test_the_catalog_lists_every_supported_provider_and_its_credential_fields(): void
    {
        $this->actingAs($this->admin(), 'sanctum')->getJson('/api/v1/admin/payment-gateways/catalog')
            ->assertOk()
            ->assertJsonFragment(['provider' => 'esewa'])
            ->assertJsonFragment(['provider' => 'khalti'])
            ->assertJsonFragment(['provider' => 'imepay'])
            ->assertJsonFragment(['provider' => 'paypal'])
            ->assertJsonFragment(['provider' => 'manual'])
            ->assertJsonFragment(['provider' => 'sandbox']);
    }

    public function test_an_admin_can_add_a_gateway_config_with_credentials(): void
    {
        $response = $this->actingAs($this->admin(), 'sanctum')->postJson('/api/v1/admin/payment-gateways', [
            'provider' => 'esewa',
            'label' => 'eSewa — main account',
            'is_sandbox' => true,
            'credentials' => ['merchant_code' => 'EPAYTEST', 'secret_key' => 'top-secret'],
        ])->assertCreated();

        $response->assertJsonPath('data.label', 'eSewa — main account');
        $response->assertJsonPath('data.credentials.merchant_code.value', 'EPAYTEST');
        $response->assertJsonPath('data.credentials.merchant_code.configured', true);
        // The secret's actual value never comes back — only that it's set.
        $response->assertJsonPath('data.credentials.secret_key.value', null);
        $response->assertJsonPath('data.credentials.secret_key.configured', true);

        $stored = PaymentGatewayConfig::first();
        $this->assertSame('top-secret', $stored->credential('secret_key'));
    }

    public function test_an_unknown_provider_is_rejected(): void
    {
        $this->actingAs($this->admin(), 'sanctum')->postJson('/api/v1/admin/payment-gateways', [
            'provider' => 'made_up_wallet',
            'label' => 'Nope',
        ])->assertUnprocessable();
    }

    public function test_updating_credentials_merges_rather_than_replaces(): void
    {
        $admin = $this->admin();
        $config = PaymentGatewayConfig::create([
            'provider' => 'esewa', 'label' => 'eSewa',
            'credentials' => ['merchant_code' => 'EPAYTEST', 'secret_key' => 'original-secret'],
        ]);

        $this->actingAs($admin, 'sanctum')->putJson("/api/v1/admin/payment-gateways/{$config->id}", [
            'credentials' => ['merchant_code' => 'NEWCODE'],
        ])->assertOk()->assertJsonPath('data.credentials.merchant_code.value', 'NEWCODE');

        $this->assertSame('original-secret', $config->fresh()->credential('secret_key'));
    }

    public function test_enabling_and_disabling_a_gateway(): void
    {
        $admin = $this->admin();
        $config = PaymentGatewayConfig::create(['provider' => 'manual', 'label' => 'Bank transfer', 'is_enabled' => false]);

        $this->actingAs($admin, 'sanctum')->putJson("/api/v1/admin/payment-gateways/{$config->id}", [
            'is_enabled' => true,
        ])->assertOk()->assertJsonPath('data.is_enabled', true);

        $this->assertTrue($config->fresh()->is_enabled);
    }

    public function test_deleting_a_gateway_config(): void
    {
        $admin = $this->admin();
        $config = PaymentGatewayConfig::create(['provider' => 'manual', 'label' => 'Bank transfer']);

        $this->actingAs($admin, 'sanctum')->deleteJson("/api/v1/admin/payment-gateways/{$config->id}")->assertNoContent();

        $this->assertDatabaseMissing('payment_gateway_configs', ['id' => $config->id]);
    }

    public function test_a_non_admin_cannot_manage_payment_gateways(): void
    {
        $buyer = User::factory()->create();

        $this->actingAs($buyer, 'sanctum')->getJson('/api/v1/admin/payment-gateways')->assertForbidden();
        $this->actingAs($buyer, 'sanctum')->postJson('/api/v1/admin/payment-gateways', ['provider' => 'manual', 'label' => 'x'])->assertForbidden();
    }

    public function test_the_public_checkout_endpoint_only_lists_enabled_gateways_and_never_credentials(): void
    {
        PaymentGatewayConfig::create(['provider' => 'manual', 'label' => 'Bank transfer', 'is_enabled' => true]);
        PaymentGatewayConfig::create([
            'provider' => 'esewa', 'label' => 'eSewa (disabled)', 'is_enabled' => false,
            'credentials' => ['merchant_code' => 'EPAYTEST', 'secret_key' => 'shh'],
        ]);

        $response = $this->getJson('/api/v1/payment-gateways')->assertOk();

        $response->assertJsonCount(1, 'data');
        $response->assertJsonPath('data.0.label', 'Bank transfer');
        $response->assertJsonMissing(['secret_key' => 'shh']);
    }
}
