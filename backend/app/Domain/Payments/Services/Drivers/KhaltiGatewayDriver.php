<?php

namespace App\Domain\Payments\Services\Drivers;

use App\Domain\Payments\Contracts\PaymentGatewayDriver;
use App\Domain\Payments\Contracts\PaymentInitiation;
use App\Models\PaymentGatewayConfig;
use App\Models\PaymentTransaction;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

/**
 * Khalti ePayment (KPG-2), Nepal. Built against Khalti's published API
 * docs — NOT verified against a live merchant account, since none was
 * available while building this. Run one real sandbox transaction against
 * a test secret key before enabling this live, and double-check the
 * sandbox/live hostnames below still match Khalti's current docs.
 *
 * Flow: server-to-server "initiate" call returns a ready-made
 * `payment_url` to send the browser to directly (no signing needed on our
 * side — the secret key travels only in this server-to-server call's
 * Authorization header, never to the browser). Khalti redirects back to
 * our return_url with `pidx` among the query params; we independently
 * confirm the outcome via a second server-to-server "lookup" call using
 * that pidx — never trusting the redirect query's own `status` alone.
 */
class KhaltiGatewayDriver implements PaymentGatewayDriver
{
    public static function providerKey(): string
    {
        return 'khalti';
    }

    public static function label(): string
    {
        return 'Khalti';
    }

    public static function credentialFields(): array
    {
        return [
            ['key' => 'secret_key', 'label' => 'Secret Key (Live or Test)', 'type' => 'password', 'required' => true],
        ];
    }

    public function initiate(PaymentGatewayConfig $config, PaymentTransaction $transaction, string $returnUrl): PaymentInitiation
    {
        $response = Http::withHeaders(['Authorization' => 'Key '.(string) $config->credential('secret_key')])
            ->timeout(15)
            ->post($this->host($config).'/api/v2/epayment/initiate/', [
                'return_url' => $returnUrl,
                'website_url' => config('app.frontend_url'),
                // Khalti's amount unit is paisa (1 NPR = 100 paisa).
                'amount' => (int) round(((float) $transaction->amount) * 100),
                'purchase_order_id' => $transaction->gateway_reference,
                'purchase_order_name' => "Featured listing boost — {$transaction->plan_days} days",
            ]);

        if (! $response->successful() || ! $response->json('payment_url')) {
            throw new RuntimeException('Khalti did not return a payment URL: '.$response->body());
        }

        return PaymentInitiation::redirect($response->json('payment_url'));
    }

    public function verifyCallback(PaymentGatewayConfig $config, PaymentTransaction $transaction, array $query): bool
    {
        $pidx = $query['pidx'] ?? null;
        if (! $pidx) {
            return false;
        }

        try {
            $response = Http::withHeaders(['Authorization' => 'Key '.(string) $config->credential('secret_key')])
                ->timeout(15)
                ->post($this->host($config).'/api/v2/epayment/lookup/', ['pidx' => $pidx]);
        } catch (\Throwable $e) {
            Log::warning('Khalti lookup call failed', ['error' => $e->getMessage()]);

            return false;
        }

        return $response->successful() && $response->json('status') === 'Completed';
    }

    private function host(PaymentGatewayConfig $config): string
    {
        return $config->is_sandbox ? 'https://dev.khalti.com' : 'https://khalti.com';
    }
}
