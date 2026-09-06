<?php

namespace App\Providers;

use App\Domain\Identity\Contracts\OtpSender;
use App\Domain\Identity\Services\LogOtpSender;
use App\Domain\Payments\Contracts\PaymentGateway;
use App\Domain\Payments\Services\SandboxPaymentGateway;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->bind(OtpSender::class, LogOtpSender::class);
        $this->app->bind(PaymentGateway::class, SandboxPaymentGateway::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
