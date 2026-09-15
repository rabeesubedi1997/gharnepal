<?php

namespace Tests\Unit\Payments;

use App\Domain\Payments\Services\Drivers\EsewaGatewayDriver;
use App\Domain\Payments\Services\Drivers\KhaltiGatewayDriver;
use App\Domain\Payments\Services\Drivers\PaypalGatewayDriver;
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

/**
 * Verifies our own request-building/signing and response-handling logic
 * against known inputs — NOT a live sandbox transaction with any of these
 * four providers, since no live merchant credentials were available while
 * building this. Run one real sandbox transaction per provider before
 * relying on it with real money.
 */
class PaymentGatewayDriversTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    private function transaction(float $amount = 500, string $currency = 'NPR'): PaymentTransaction
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
            'plan_key' => 'week', 'plan_days' => 7, 'amount' => $amount, 'currency' => $currency,
            'gateway' => 'test', 'gateway_reference' => 'TX-TEST-'.uniqid(), 'status' => PaymentTransaction::STATUS_PENDING,
        ]);
    }

    // ---- eSewa ----------------------------------------------------------

    public function test_esewa_initiate_builds_a_correctly_signed_form_post(): void
    {
        $config = PaymentGatewayConfig::create([
            'provider' => 'esewa', 'label' => 'eSewa', 'is_sandbox' => true,
            'credentials' => ['merchant_code' => 'EPAYTEST', 'secret_key' => 'my-secret'],
        ]);
        $transaction = $this->transaction(500.00);

        $initiation = (new EsewaGatewayDriver)->initiate($config, $transaction, 'https://app.test/callback?ref=X');

        $this->assertSame('form_post', $initiation->mode);
        $this->assertSame('https://rc-epay.esewa.com.np/api/epay/main/v2/form', $initiation->redirectUrl);
        $this->assertSame('500.00', $initiation->formFields['total_amount']);
        $this->assertSame($transaction->gateway_reference, $initiation->formFields['transaction_uuid']);

        $expectedMessage = "total_amount=500.00,transaction_uuid={$transaction->gateway_reference},product_code=EPAYTEST";
        $expectedSignature = base64_encode(hash_hmac('sha256', $expectedMessage, 'my-secret', true));
        $this->assertSame($expectedSignature, $initiation->formFields['signature']);
    }

    public function test_esewa_verify_callback_accepts_a_correctly_signed_complete_payload(): void
    {
        Http::fake(['rc.esewa.com.np/*' => Http::response(['status' => 'COMPLETE'])]);

        $config = PaymentGatewayConfig::create([
            'provider' => 'esewa', 'label' => 'eSewa', 'is_sandbox' => true,
            'credentials' => ['merchant_code' => 'EPAYTEST', 'secret_key' => 'my-secret'],
        ]);
        $transaction = $this->transaction(500.00);

        $payload = ['total_amount' => '500.00', 'transaction_uuid' => $transaction->gateway_reference, 'product_code' => 'EPAYTEST', 'status' => 'COMPLETE'];
        $signedFieldNames = 'total_amount,transaction_uuid,product_code';
        $message = "total_amount=500.00,transaction_uuid={$transaction->gateway_reference},product_code=EPAYTEST";
        $payload['signed_field_names'] = $signedFieldNames;
        $payload['signature'] = base64_encode(hash_hmac('sha256', $message, 'my-secret', true));

        $ok = (new EsewaGatewayDriver)->verifyCallback($config, $transaction, ['data' => base64_encode(json_encode($payload))]);

        $this->assertTrue($ok);
    }

    public function test_esewa_verify_callback_rejects_a_tampered_signature(): void
    {
        $config = PaymentGatewayConfig::create([
            'provider' => 'esewa', 'label' => 'eSewa', 'is_sandbox' => true,
            'credentials' => ['merchant_code' => 'EPAYTEST', 'secret_key' => 'my-secret'],
        ]);
        $transaction = $this->transaction(500.00);

        $payload = [
            'total_amount' => '999999.00', // tampered — doesn't match what was actually signed
            'transaction_uuid' => $transaction->gateway_reference,
            'product_code' => 'EPAYTEST',
            'status' => 'COMPLETE',
            'signed_field_names' => 'total_amount,transaction_uuid,product_code',
            'signature' => base64_encode(hash_hmac('sha256', 'total_amount=500.00,transaction_uuid=X,product_code=EPAYTEST', 'my-secret', true)),
        ];

        $ok = (new EsewaGatewayDriver)->verifyCallback($config, $transaction, ['data' => base64_encode(json_encode($payload))]);

        $this->assertFalse($ok);
    }

    public function test_esewa_verify_callback_does_not_fail_a_valid_signature_over_a_network_hiccup_on_the_secondary_check(): void
    {
        Http::fake(['rc.esewa.com.np/*' => fn () => throw new \Exception('connection reset')]);

        $config = PaymentGatewayConfig::create([
            'provider' => 'esewa', 'label' => 'eSewa', 'is_sandbox' => true,
            'credentials' => ['merchant_code' => 'EPAYTEST', 'secret_key' => 'my-secret'],
        ]);
        $transaction = $this->transaction(500.00);

        $message = "total_amount=500.00,transaction_uuid={$transaction->gateway_reference},product_code=EPAYTEST";
        $payload = [
            'total_amount' => '500.00', 'transaction_uuid' => $transaction->gateway_reference, 'product_code' => 'EPAYTEST',
            'status' => 'COMPLETE', 'signed_field_names' => 'total_amount,transaction_uuid,product_code',
            'signature' => base64_encode(hash_hmac('sha256', $message, 'my-secret', true)),
        ];

        $ok = (new EsewaGatewayDriver)->verifyCallback($config, $transaction, ['data' => base64_encode(json_encode($payload))]);

        $this->assertTrue($ok);
    }

    // ---- Khalti ----------------------------------------------------------

    public function test_khalti_initiate_sends_amount_in_paisa_and_returns_the_payment_url(): void
    {
        Http::fake(['dev.khalti.com/*' => Http::response(['pidx' => 'abc123', 'payment_url' => 'https://dev.khalti.com/pay/abc123'])]);

        $config = PaymentGatewayConfig::create([
            'provider' => 'khalti', 'label' => 'Khalti', 'is_sandbox' => true,
            'credentials' => ['secret_key' => 'test-secret'],
        ]);
        $transaction = $this->transaction(500.00);

        $initiation = (new KhaltiGatewayDriver)->initiate($config, $transaction, 'https://app.test/callback?ref=X');

        $this->assertSame('redirect', $initiation->mode);
        $this->assertSame('https://dev.khalti.com/pay/abc123', $initiation->redirectUrl);

        Http::assertSent(function ($request) {
            return $request->hasHeader('Authorization', 'Key test-secret')
                && $request['amount'] === 50000; // 500 NPR = 50000 paisa
        });
    }

    public function test_khalti_verify_callback_trusts_only_a_completed_lookup_response(): void
    {
        Http::fake(['dev.khalti.com/*' => Http::response(['status' => 'Completed'])]);

        $config = PaymentGatewayConfig::create([
            'provider' => 'khalti', 'label' => 'Khalti', 'is_sandbox' => true,
            'credentials' => ['secret_key' => 'test-secret'],
        ]);
        $transaction = $this->transaction();

        $this->assertTrue((new KhaltiGatewayDriver)->verifyCallback($config, $transaction, ['pidx' => 'abc123']));
    }

    public function test_khalti_verify_callback_rejects_a_pending_lookup_response(): void
    {
        Http::fake(['dev.khalti.com/*' => Http::response(['status' => 'Pending'])]);

        $config = PaymentGatewayConfig::create([
            'provider' => 'khalti', 'label' => 'Khalti', 'is_sandbox' => true,
            'credentials' => ['secret_key' => 'test-secret'],
        ]);
        $transaction = $this->transaction();

        $this->assertFalse((new KhaltiGatewayDriver)->verifyCallback($config, $transaction, ['pidx' => 'abc123']));
    }

    public function test_khalti_verify_callback_without_a_pidx_never_calls_out_at_all(): void
    {
        Http::fake();

        $config = PaymentGatewayConfig::create(['provider' => 'khalti', 'label' => 'Khalti', 'credentials' => ['secret_key' => 'x']]);

        $this->assertFalse((new KhaltiGatewayDriver)->verifyCallback($config, $this->transaction(), []));
        Http::assertNothingSent();
    }

    // ---- PayPal ------------------------------------------------------------

    public function test_paypal_initiate_gets_a_token_then_creates_an_order_and_returns_the_approve_link(): void
    {
        Http::fake([
            'api-m.sandbox.paypal.com/v1/oauth2/token' => Http::response(['access_token' => 'tok-123']),
            'api-m.sandbox.paypal.com/v2/checkout/orders' => Http::response([
                'id' => 'ORDER1',
                'links' => [
                    ['rel' => 'self', 'href' => 'https://api-m.sandbox.paypal.com/v2/checkout/orders/ORDER1'],
                    ['rel' => 'approve', 'href' => 'https://www.sandbox.paypal.com/checkoutnow?token=ORDER1'],
                ],
            ]),
        ]);

        $config = PaymentGatewayConfig::create([
            'provider' => 'paypal', 'label' => 'PayPal', 'is_sandbox' => true,
            'credentials' => ['client_id' => 'cid', 'client_secret' => 'csecret'],
        ]);
        $transaction = $this->transaction(10.00, 'USD');

        $initiation = (new PaypalGatewayDriver)->initiate($config, $transaction, 'https://app.test/callback?ref=X');

        $this->assertSame('redirect', $initiation->mode);
        $this->assertSame('https://www.sandbox.paypal.com/checkoutnow?token=ORDER1', $initiation->redirectUrl);
    }

    public function test_paypal_verify_callback_captures_the_order_and_trusts_the_capture_status(): void
    {
        Http::fake([
            'api-m.sandbox.paypal.com/v1/oauth2/token' => Http::response(['access_token' => 'tok-123']),
            'api-m.sandbox.paypal.com/v2/checkout/orders/ORDER1/capture' => Http::response(['status' => 'COMPLETED']),
        ]);

        $config = PaymentGatewayConfig::create([
            'provider' => 'paypal', 'label' => 'PayPal', 'is_sandbox' => true,
            'credentials' => ['client_id' => 'cid', 'client_secret' => 'csecret'],
        ]);
        $transaction = $this->transaction(10.00, 'USD');

        $ok = (new PaypalGatewayDriver)->verifyCallback($config, $transaction, ['token' => 'ORDER1']);

        $this->assertTrue($ok);
    }

    public function test_paypal_verify_callback_without_a_token_never_calls_out_at_all(): void
    {
        Http::fake();

        $config = PaymentGatewayConfig::create(['provider' => 'paypal', 'label' => 'PayPal', 'credentials' => ['client_id' => 'x', 'client_secret' => 'y']]);

        $this->assertFalse((new PaypalGatewayDriver)->verifyCallback($config, $this->transaction(), []));
        Http::assertNothingSent();
    }
}
