<?php

namespace Tests\Unit\Payments;

use App\Domain\Payments\Contracts\PaymentInitiation;
use App\Domain\Payments\Services\Drivers\SandboxGatewayDriver;
use App\Models\Municipality;
use App\Models\PaymentGatewayConfig;
use App\Models\PaymentTransaction;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\User;
use App\Models\Ward;
use Database\Seeders\NepalLocationSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use RuntimeException;
use Tests\TestCase;

class PaymentGatewayBindingTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(NepalLocationSeeder::class);
    }

    private function transaction(): PaymentTransaction
    {
        $owner = User::factory()->create();
        $municipality = Municipality::where('code', 'M-KTM')->firstOrFail();
        $ward = Ward::where('municipality_id', $municipality->id)->where('ward_number', 1)->firstOrFail();

        $property = Property::create([
            'owner_user_id' => $owner->id,
            'created_by' => $owner->id,
            'property_type' => 'apartment',
            'bedrooms' => 2,
            'bathrooms' => 1,
            'total_area_sqm' => 80,
        ]);
        $property->address()->create([
            'province_id' => $municipality->district->province_id,
            'district_id' => $municipality->district_id,
            'municipality_id' => $municipality->id,
            'ward_id' => $ward->id,
        ]);
        $listing = $property->listings()->create([
            'purpose' => 'rent',
            'price' => 25000,
            'price_period' => 'monthly',
            'title' => 'Test listing',
            'slug' => 'test-listing-'.uniqid(),
            'status' => PropertyListing::STATUS_PUBLISHED,
            'published_at' => now(),
            'created_by' => $owner->id,
        ]);

        return PaymentTransaction::create([
            'user_id' => $owner->id,
            'property_listing_id' => $listing->id,
            'plan_key' => 'week',
            'plan_days' => 7,
            'amount' => 500,
            'currency' => 'NPR',
            'gateway' => 'sandbox',
            'gateway_reference' => 'TX-TEST',
            'status' => PaymentTransaction::STATUS_PENDING,
        ]);
    }

    public function test_sandbox_driver_refuses_to_initiate_in_production_without_explicit_opt_in(): void
    {
        app()->instance('env', 'production');
        config(['services.payments.allow_sandbox_in_production' => false]);

        $config = PaymentGatewayConfig::create(['provider' => 'sandbox', 'label' => 'Sandbox']);

        $this->expectException(RuntimeException::class);
        (new SandboxGatewayDriver)->initiate($config, $this->transaction(), 'https://example.test/callback');
    }

    public function test_sandbox_driver_initiates_in_production_when_explicitly_allowed(): void
    {
        app()->instance('env', 'production');
        config(['services.payments.allow_sandbox_in_production' => true]);

        $config = PaymentGatewayConfig::create(['provider' => 'sandbox', 'label' => 'Sandbox']);

        $initiation = (new SandboxGatewayDriver)->initiate($config, $this->transaction(), 'https://example.test/callback');

        $this->assertInstanceOf(PaymentInitiation::class, $initiation);
        $this->assertSame('inline', $initiation->mode);
    }

    public function test_sandbox_driver_initiates_normally_outside_production(): void
    {
        app()->instance('env', 'local');
        config(['services.payments.allow_sandbox_in_production' => false]);

        $config = PaymentGatewayConfig::create(['provider' => 'sandbox', 'label' => 'Sandbox']);

        $initiation = (new SandboxGatewayDriver)->initiate($config, $this->transaction(), 'https://example.test/callback');

        $this->assertSame('inline', $initiation->mode);
    }
}
