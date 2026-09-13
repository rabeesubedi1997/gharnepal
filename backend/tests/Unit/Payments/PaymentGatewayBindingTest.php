<?php

namespace Tests\Unit\Payments;

use App\Domain\Payments\Contracts\PaymentGateway;
use App\Domain\Payments\Services\SandboxPaymentGateway;
use App\Providers\AppServiceProvider;
use RuntimeException;
use Tests\TestCase;

class PaymentGatewayBindingTest extends TestCase
{
    public function test_sandbox_gateway_refuses_to_bind_in_production_without_explicit_opt_in(): void
    {
        app()->instance('env', 'production');
        config(['services.payments.allow_sandbox_in_production' => false]);

        (new AppServiceProvider(app()))->register();

        $this->expectException(RuntimeException::class);
        app(PaymentGateway::class);
    }

    public function test_sandbox_gateway_binds_in_production_when_explicitly_allowed(): void
    {
        app()->instance('env', 'production');
        config(['services.payments.allow_sandbox_in_production' => true]);

        (new AppServiceProvider(app()))->register();

        $this->assertInstanceOf(SandboxPaymentGateway::class, app(PaymentGateway::class));
    }

    public function test_sandbox_gateway_binds_normally_outside_production(): void
    {
        app()->instance('env', 'local');
        config(['services.payments.allow_sandbox_in_production' => false]);

        (new AppServiceProvider(app()))->register();

        $this->assertInstanceOf(SandboxPaymentGateway::class, app(PaymentGateway::class));
    }
}
