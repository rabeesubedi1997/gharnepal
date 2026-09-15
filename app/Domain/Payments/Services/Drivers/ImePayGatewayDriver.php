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
 * IME Pay (Nepal) — LOWEST-CONFIDENCE driver of the four. IME Pay's
 * merchant integration is far less consistently/publicly documented than
 * eSewa, Khalti, or PayPal, so unlike those three this is a best-effort
 * scaffold built from the commonly-described "get a token, redirect to
 * WebCheckout, verify by transaction status" shape — the exact hostnames,
 * endpoint paths, and field names below are NOT verified and should be
 * checked line-by-line against IME Pay's current merchant integration
 * document (ask your IME Pay relationship manager for it) before this is
 * ever enabled with real credentials. Treat every URL/field name here as a
 * placeholder to confirm, not a known-good value.
 *
 * Credentials this expects: `merchant_code`, `username`, `password` — the
 * three values IME Pay merchant onboarding typically issues.
 */
class ImePayGatewayDriver implements PaymentGatewayDriver
{
    public static function providerKey(): string
    {
        return 'imepay';
    }

    public static function label(): string
    {
        return 'IME Pay (best-effort — verify against IME Pay\'s docs before enabling)';
    }

    public static function credentialFields(): array
    {
        return [
            ['key' => 'merchant_code', 'label' => 'Merchant Code', 'type' => 'text', 'required' => true],
            ['key' => 'username', 'label' => 'API Username', 'type' => 'text', 'required' => true],
            ['key' => 'password', 'label' => 'API Password', 'type' => 'password', 'required' => true],
        ];
    }

    public function initiate(PaymentGatewayConfig $config, PaymentTransaction $transaction, string $returnUrl): PaymentInitiation
    {
        $host = $this->apiHost($config);

        $tokenResponse = Http::asForm()->timeout(15)->post("{$host}/api1/Web/GetToken", [
            'MerchantCode' => $config->credential('merchant_code'),
            'Username' => $config->credential('username'),
            'Password' => $config->credential('password'),
            'Amount' => number_format((float) $transaction->amount, 2, '.', ''),
            'RefId' => $transaction->gateway_reference,
        ]);

        $tokenId = $tokenResponse->json('TokenId');
        if (! $tokenResponse->successful() || ! $tokenId) {
            throw new RuntimeException('IME Pay did not return a token: '.$tokenResponse->body());
        }

        $checkoutHost = $this->checkoutHost($config);
        $checkoutUrl = "{$checkoutHost}/WebCheckout/index?".http_build_query([
            'MerchantCode' => $config->credential('merchant_code'),
            'TokenId' => $tokenId,
            'Amount' => number_format((float) $transaction->amount, 2, '.', ''),
            'RefId' => $transaction->gateway_reference,
            'RedirectURL' => $returnUrl,
        ]);

        return PaymentInitiation::redirect($checkoutUrl);
    }

    public function verifyCallback(PaymentGatewayConfig $config, PaymentTransaction $transaction, array $query): bool
    {
        $tranId = $query['TranId'] ?? null;
        if (! $tranId) {
            return false;
        }

        try {
            $response = Http::asForm()->timeout(15)->post($this->apiHost($config).'/api1/Web/CheckTransactionStatus', [
                'MerchantCode' => $config->credential('merchant_code'),
                'Username' => $config->credential('username'),
                'Password' => $config->credential('password'),
                'TranId' => $tranId,
                'RefId' => $transaction->gateway_reference,
            ]);
        } catch (\Throwable $e) {
            Log::warning('IME Pay status check call failed', ['error' => $e->getMessage()]);

            return false;
        }

        return $response->successful() && in_array($response->json('ResponseCode'), ['0', 0], true);
    }

    private function apiHost(PaymentGatewayConfig $config): string
    {
        return $config->is_sandbox ? 'https://stg.imepay.com.np:7071' : 'https://api.imepay.com.np';
    }

    private function checkoutHost(PaymentGatewayConfig $config): string
    {
        return $config->is_sandbox ? 'https://stg.imepay.com.np:7076' : 'https://pay.imepay.com.np';
    }
}
