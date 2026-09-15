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
 * PayPal Orders v2 (REST). Built against PayPal's published API docs —
 * NOT verified against a live sandbox account, since none was available
 * while building this. Run one real sandbox transaction before enabling
 * this live.
 *
 * IMPORTANT business constraint, not a code bug: PayPal does not settle
 * in Nepalese Rupees at all — NPR is not one of its supported currencies.
 * A config using this driver must price in a currency PayPal actually
 * supports (USD, EUR, GBP, ...); pointing it at an NPR-denominated
 * transaction will simply fail at PayPal's end.
 *
 * Flow: an OAuth2 client-credentials token (client_id/client_secret, Basic
 * auth) authorizes a "create order" call, whose response includes an
 * `approve` link to send the browser to. PayPal redirects back to our
 * return_url with its own `token` (the order id) appended; we then make a
 * second server-to-server "capture" call against that order id — the
 * capture response's own status is the actual source of truth, not
 * anything in the redirect query.
 */
class PaypalGatewayDriver implements PaymentGatewayDriver
{
    public static function providerKey(): string
    {
        return 'paypal';
    }

    public static function label(): string
    {
        return 'PayPal (USD/EUR/GBP etc. only — not NPR)';
    }

    public static function credentialFields(): array
    {
        return [
            ['key' => 'client_id', 'label' => 'Client ID', 'type' => 'text', 'required' => true],
            ['key' => 'client_secret', 'label' => 'Client Secret', 'type' => 'password', 'required' => true],
        ];
    }

    public function initiate(PaymentGatewayConfig $config, PaymentTransaction $transaction, string $returnUrl): PaymentInitiation
    {
        $token = $this->accessToken($config);

        $response = Http::withToken($token)->timeout(15)->post($this->host($config).'/v2/checkout/orders', [
            'intent' => 'CAPTURE',
            'purchase_units' => [[
                'reference_id' => $transaction->gateway_reference,
                'amount' => [
                    'currency_code' => $transaction->currency,
                    'value' => number_format((float) $transaction->amount, 2, '.', ''),
                ],
            ]],
            'application_context' => [
                'return_url' => $returnUrl,
                'cancel_url' => $returnUrl,
            ],
        ]);

        $approveUrl = collect($response->json('links'))->firstWhere('rel', 'approve')['href'] ?? null;

        if (! $response->successful() || ! $approveUrl) {
            throw new RuntimeException('PayPal did not return an approval link: '.$response->body());
        }

        return PaymentInitiation::redirect($approveUrl);
    }

    public function verifyCallback(PaymentGatewayConfig $config, PaymentTransaction $transaction, array $query): bool
    {
        $orderId = $query['token'] ?? null;
        if (! $orderId) {
            return false;
        }

        try {
            $token = $this->accessToken($config);
            $response = Http::withToken($token)->timeout(15)
                ->post($this->host($config)."/v2/checkout/orders/{$orderId}/capture");
        } catch (\Throwable $e) {
            Log::warning('PayPal capture call failed', ['error' => $e->getMessage()]);

            return false;
        }

        return $response->successful() && $response->json('status') === 'COMPLETED';
    }

    private function accessToken(PaymentGatewayConfig $config): string
    {
        $response = Http::asForm()
            ->withBasicAuth((string) $config->credential('client_id'), (string) $config->credential('client_secret'))
            ->timeout(15)
            ->post($this->host($config).'/v1/oauth2/token', ['grant_type' => 'client_credentials']);

        if (! $response->successful() || ! $response->json('access_token')) {
            throw new RuntimeException('Could not obtain a PayPal access token: '.$response->body());
        }

        return $response->json('access_token');
    }

    private function host(PaymentGatewayConfig $config): string
    {
        return $config->is_sandbox ? 'https://api-m.sandbox.paypal.com' : 'https://api-m.paypal.com';
    }
}
