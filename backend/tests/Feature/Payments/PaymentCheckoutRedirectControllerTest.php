<?php

namespace Tests\Feature\Payments;

use App\Models\Municipality;
use App\Models\PaymentGatewayConfig;
use App\Models\PaymentTransaction;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\User;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PaymentCheckoutRedirectControllerTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    private function pendingTransaction(PaymentGatewayConfig $gatewayConfig, ?array $checkoutSnapshot): PaymentTransaction
    {
        $owner = User::factory()->create();
        $municipality = Municipality::where('code', 'M-KTM')->firstOrFail();
        $ward = Ward::where('municipality_id', $municipality->id)->where('ward_number', 1)->firstOrFail();

        $property = Property::create([
            'owner_user_id' => $owner->id, 'created_by' => $owner->id,
            'property_type' => 'apartment', 'bedrooms' => 2, 'bathrooms' => 1, 'total_area_sqm' => 80,
        ]);
        $property->address()->create([
            'province_id' => $municipality->district->province_id,
            'district_id' => $municipality->district_id,
            'municipality_id' => $municipality->id,
            'ward_id' => $ward->id,
        ]);
        $listing = $property->listings()->create([
            'purpose' => 'rent', 'price' => 25000, 'price_period' => 'monthly',
            'title' => 'Test listing', 'slug' => 'test-listing-'.uniqid(),
            'status' => PropertyListing::STATUS_PUBLISHED, 'published_at' => now(), 'created_by' => $owner->id,
        ]);

        return PaymentTransaction::create([
            'user_id' => $owner->id, 'property_listing_id' => $listing->id,
            'plan_key' => 'week', 'plan_days' => 7, 'amount' => 500, 'currency' => 'NPR',
            'gateway' => $gatewayConfig->provider, 'gateway_config_id' => $gatewayConfig->id,
            'gateway_reference' => 'TX-CO-TEST', 'checkout_snapshot' => $checkoutSnapshot,
            'status' => PaymentTransaction::STATUS_PENDING,
        ]);
    }

    public function test_an_unknown_reference_is_a_404(): void
    {
        $this->get('/api/v1/payments/checkout/does-not-exist')->assertNotFound();
    }

    public function test_a_transaction_with_no_checkout_snapshot_is_a_404(): void
    {
        $config = PaymentGatewayConfig::create(['provider' => 'manual', 'label' => 'Bank transfer']);
        $transaction = $this->pendingTransaction($config, null);

        $this->get("/api/v1/payments/checkout/{$transaction->gateway_reference}")->assertNotFound();
    }

    public function test_redirect_mode_sends_the_browser_straight_to_the_gateway_url(): void
    {
        $config = PaymentGatewayConfig::create(['provider' => 'khalti', 'label' => 'Khalti']);
        $transaction = $this->pendingTransaction($config, [
            'mode' => 'redirect', 'redirect_url' => 'https://khalti.com/pay/xyz', 'form_fields' => [], 'instructions' => null,
        ]);

        $this->get("/api/v1/payments/checkout/{$transaction->gateway_reference}")
            ->assertRedirect('https://khalti.com/pay/xyz');
    }

    public function test_form_post_mode_renders_an_auto_submitting_form_with_every_field(): void
    {
        $config = PaymentGatewayConfig::create(['provider' => 'esewa', 'label' => 'eSewa']);
        $transaction = $this->pendingTransaction($config, [
            'mode' => 'form_post',
            'redirect_url' => 'https://rc.esewa.com.np/api/epay/main/v2/form',
            'form_fields' => ['amount' => '500', 'transaction_uuid' => 'TX-CO-TEST', 'product_code' => 'EPAYTEST'],
            'instructions' => null,
        ]);

        $response = $this->get("/api/v1/payments/checkout/{$transaction->gateway_reference}");

        $response->assertOk();
        $response->assertSee('action="https://rc.esewa.com.np/api/epay/main/v2/form"', false);
        $response->assertSee('name="amount" value="500"', false);
        $response->assertSee('name="product_code" value="EPAYTEST"', false);
    }

    public function test_inline_mode_just_sends_the_buyer_back_to_their_payment_history(): void
    {
        $config = PaymentGatewayConfig::create(['provider' => 'sandbox', 'label' => 'Sandbox']);
        $transaction = $this->pendingTransaction($config, [
            'mode' => 'inline', 'redirect_url' => null, 'form_fields' => [], 'instructions' => null,
        ]);

        $this->get("/api/v1/payments/checkout/{$transaction->gateway_reference}")
            ->assertRedirect(rtrim(config('app.frontend_url'), '/').'/account/payments');
    }
}
