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
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class PaymentCallbackControllerTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    private function pendingTransaction(PaymentGatewayConfig $gatewayConfig): PaymentTransaction
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
            'gateway_reference' => 'TX-CB-TEST', 'status' => PaymentTransaction::STATUS_PENDING,
        ]);
    }

    public function test_a_missing_reference_redirects_to_a_not_found_status(): void
    {
        $config = PaymentGatewayConfig::create(['provider' => 'manual', 'label' => 'Bank transfer']);

        $this->get("/api/v1/payments/callback/{$config->id}?ref=does-not-exist")
            ->assertRedirect(config('app.frontend_url').'/account/payments?status=not_found');
    }

    public function test_an_esewa_callback_with_a_valid_signature_completes_the_transaction_and_redirects_success(): void
    {
        Http::fake(['rc.esewa.com.np/*' => Http::response(['status' => 'COMPLETE'])]);

        $config = PaymentGatewayConfig::create([
            'provider' => 'esewa', 'label' => 'eSewa', 'is_sandbox' => true,
            'credentials' => ['merchant_code' => 'EPAYTEST', 'secret_key' => 'my-secret'],
        ]);
        $transaction = $this->pendingTransaction($config);

        $message = "total_amount=500.00,transaction_uuid={$transaction->gateway_reference},product_code=EPAYTEST";
        $payload = [
            'total_amount' => '500.00', 'transaction_uuid' => $transaction->gateway_reference, 'product_code' => 'EPAYTEST',
            'status' => 'COMPLETE', 'signed_field_names' => 'total_amount,transaction_uuid,product_code',
            'signature' => base64_encode(hash_hmac('sha256', $message, 'my-secret', true)),
        ];

        $this->get("/api/v1/payments/callback/{$config->id}?ref={$transaction->gateway_reference}&data=".base64_encode(json_encode($payload)))
            ->assertRedirect(config('app.frontend_url').'/account/payments?status=success');

        $this->assertSame('completed', $transaction->fresh()->status);
        $this->assertTrue($transaction->fresh()->propertyListing->isFeatured());
    }

    public function test_an_esewa_callback_with_a_bad_signature_fails_the_transaction_and_redirects_failed(): void
    {
        $config = PaymentGatewayConfig::create([
            'provider' => 'esewa', 'label' => 'eSewa', 'is_sandbox' => true,
            'credentials' => ['merchant_code' => 'EPAYTEST', 'secret_key' => 'my-secret'],
        ]);
        $transaction = $this->pendingTransaction($config);

        $payload = [
            'total_amount' => '500.00', 'transaction_uuid' => $transaction->gateway_reference, 'product_code' => 'EPAYTEST',
            'status' => 'COMPLETE', 'signed_field_names' => 'total_amount,transaction_uuid,product_code',
            'signature' => 'not-a-real-signature',
        ];

        $this->get("/api/v1/payments/callback/{$config->id}?ref={$transaction->gateway_reference}&data=".base64_encode(json_encode($payload)))
            ->assertRedirect(config('app.frontend_url').'/account/payments?status=failed');

        $this->assertSame('failed', $transaction->fresh()->status);
    }

    public function test_a_second_callback_for_an_already_settled_transaction_does_not_reprocess_it(): void
    {
        $config = PaymentGatewayConfig::create(['provider' => 'manual', 'label' => 'Bank transfer']);
        $transaction = $this->pendingTransaction($config);
        $transaction->update(['status' => PaymentTransaction::STATUS_COMPLETED, 'completed_at' => now()]);

        $this->get("/api/v1/payments/callback/{$config->id}?ref={$transaction->gateway_reference}&anything=else")
            ->assertRedirect(config('app.frontend_url').'/account/payments?status=success');

        // Still exactly the one completed row — no duplicate boost applied.
        $this->assertSame(1, PaymentTransaction::where('id', $transaction->id)->count());
    }
}
