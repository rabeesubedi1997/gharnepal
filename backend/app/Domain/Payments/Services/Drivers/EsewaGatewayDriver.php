<?php

namespace App\Domain\Payments\Services\Drivers;

use App\Domain\Payments\Contracts\PaymentGatewayDriver;
use App\Domain\Payments\Contracts\PaymentInitiation;
use App\Models\PaymentGatewayConfig;
use App\Models\PaymentTransaction;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * eSewa ePay v2 (Nepal). Built against eSewa's published merchant
 * integration docs — NOT verified against a live merchant account, since
 * none was available while building this. Run one real sandbox transaction
 * against a test merchant account before enabling this live.
 *
 * Flow: an HTML form the browser POSTs directly to eSewa, signed with
 * HMAC-SHA256 over the fields named in `signed_field_names` (comma-joined
 * "key=value", in that exact order), Base64-encoded. eSewa redirects back
 * to our `success_url`/`failure_url` with a `data` query param — a
 * Base64-encoded JSON object carrying its own `signed_field_names` +
 * `signature`, which we re-verify the same way before trusting anything
 * in it. The extra server-to-server status call afterward is a
 * best-effort secondary check: if the signature already checks out, a
 * network hiccup on that second call must not flip a real success into a
 * failure — only an explicit non-complete status from it does. Confirm
 * the exact status-check host/path against eSewa's current docs before
 * relying on it.
 */
class EsewaGatewayDriver implements PaymentGatewayDriver
{
    public static function providerKey(): string
    {
        return 'esewa';
    }

    public static function label(): string
    {
        return 'eSewa';
    }

    public static function credentialFields(): array
    {
        return [
            ['key' => 'merchant_code', 'label' => 'Merchant / Product Code', 'type' => 'text', 'required' => true],
            ['key' => 'secret_key', 'label' => 'Secret Key', 'type' => 'password', 'required' => true],
        ];
    }

    public function initiate(PaymentGatewayConfig $config, PaymentTransaction $transaction, string $returnUrl): PaymentInitiation
    {
        $productCode = $config->credential('merchant_code') ?: 'EPAYTEST';
        $secretKey = (string) $config->credential('secret_key');
        $totalAmount = number_format((float) $transaction->amount, 2, '.', '');
        $signedFieldNames = 'total_amount,transaction_uuid,product_code';

        $signature = $this->sign([
            'total_amount' => $totalAmount,
            'transaction_uuid' => $transaction->gateway_reference,
            'product_code' => $productCode,
        ], $signedFieldNames, $secretKey);

        $formAction = $config->is_sandbox
            ? 'https://rc-epay.esewa.com.np/api/epay/main/v2/form'
            : 'https://epay.esewa.com.np/api/epay/main/v2/form';

        return PaymentInitiation::formPost($formAction, [
            'amount' => $totalAmount,
            'tax_amount' => '0',
            'total_amount' => $totalAmount,
            'transaction_uuid' => $transaction->gateway_reference,
            'product_code' => $productCode,
            'product_service_charge' => '0',
            'product_delivery_charge' => '0',
            'success_url' => $returnUrl,
            'failure_url' => $returnUrl,
            'signed_field_names' => $signedFieldNames,
            'signature' => $signature,
        ]);
    }

    public function verifyCallback(PaymentGatewayConfig $config, PaymentTransaction $transaction, array $query): bool
    {
        $encoded = $query['data'] ?? null;
        if (! $encoded || ! is_string($encoded)) {
            return false;
        }

        $payload = json_decode(base64_decode($encoded, true) ?: '', true);
        if (! is_array($payload)) {
            return false;
        }

        $signedFieldNames = (string) ($payload['signed_field_names'] ?? '');
        if (! $signedFieldNames) {
            return false;
        }

        $expected = $this->sign($payload, $signedFieldNames, (string) $config->credential('secret_key'));
        if (! hash_equals($expected, (string) ($payload['signature'] ?? ''))) {
            return false;
        }

        if (($payload['status'] ?? null) !== 'COMPLETE') {
            return false;
        }

        // The secondary check only ever narrows a "yes" to a "no" on an
        // explicit contradiction from eSewa itself — a network hiccup or an
        // unreachable/wrong endpoint must not undo a signature that already
        // checked out.
        return $this->bestEffortStatusCheck($config, $payload) !== false;
    }

    /** @param array<string,mixed> $fields */
    private function sign(array $fields, string $signedFieldNames, string $secretKey): string
    {
        $message = collect(explode(',', $signedFieldNames))
            ->map(fn (string $key) => trim($key).'='.($fields[trim($key)] ?? ''))
            ->implode(',');

        return base64_encode(hash_hmac('sha256', $message, $secretKey, true));
    }

    /**
     * @param  array<string,mixed>  $payload
     * @return bool|null true/false = a definite answer from eSewa itself; null = inconclusive (call failed, or eSewa gave no clear status) — treated as "don't override".
     */
    private function bestEffortStatusCheck(PaymentGatewayConfig $config, array $payload): ?bool
    {
        $host = $config->is_sandbox ? 'https://rc.esewa.com.np' : 'https://epay.esewa.com.np';

        try {
            $response = Http::timeout(10)->get("{$host}/api/epay/transaction/status/", [
                'product_code' => $config->credential('merchant_code') ?: 'EPAYTEST',
                'total_amount' => $payload['total_amount'] ?? '',
                'transaction_uuid' => $payload['transaction_uuid'] ?? '',
            ]);

            if (! $response->successful() || ! $response->json('status')) {
                return null;
            }

            if ($response->json('status') !== 'COMPLETE') {
                Log::warning('eSewa status check contradicted a signature-verified callback', [
                    'transaction_uuid' => $payload['transaction_uuid'] ?? null,
                    'status_response' => $response->json(),
                ]);

                return false;
            }

            return true;
        } catch (\Throwable $e) {
            Log::warning('eSewa status check call failed (non-blocking)', ['error' => $e->getMessage()]);

            return null;
        }
    }
}
