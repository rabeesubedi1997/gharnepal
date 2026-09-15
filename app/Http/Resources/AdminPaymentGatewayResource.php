<?php

namespace App\Http\Resources;

use App\Domain\Payments\Services\PaymentGatewayDriverRegistry;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Admin-facing view of one gateway config. Every credential field's actual
 * value is masked to `configured: true/false` — a `type: 'password'` field
 * never comes back at all, only whether one is currently set — except
 * plain `text` fields (merchant/client IDs, not secrets), which do come
 * back in full since an admin genuinely needs to see/confirm those.
 */
class AdminPaymentGatewayResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $schema = collect(PaymentGatewayDriverRegistry::catalog())->firstWhere('provider', $this->provider)['fields'] ?? [];
        $stored = $this->credentials ?? [];

        return [
            'id' => $this->id,
            'provider' => $this->provider,
            'label' => $this->label,
            'is_enabled' => $this->is_enabled,
            'is_sandbox' => $this->is_sandbox,
            'sort_order' => $this->sort_order,
            'instructions' => $this->instructions,
            'credentials' => collect($schema)->mapWithKeys(function (array $field) use ($stored) {
                $value = $stored[$field['key']] ?? null;
                $configured = $value !== null && $value !== '';

                return [$field['key'] => [
                    'value' => $field['type'] === 'password' ? null : $value,
                    'configured' => $configured,
                ]];
            }),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
