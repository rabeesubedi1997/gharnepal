<?php

namespace App\Http\Resources;

use App\Domain\Assistant\Services\AiAssistantDriverRegistry;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Admin-facing view of one AI provider config. Mirrors
 * AdminPaymentGatewayResource: every `type: 'password'` field is masked to
 * `configured: true/false` and never comes back in full; plain `text`
 * fields (like the model name) do come back, since an admin needs to
 * see/confirm those.
 */
class AdminAiProviderConfigResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $schema = collect(AiAssistantDriverRegistry::catalog())->firstWhere('provider', $this->provider)['fields'] ?? [];
        $stored = $this->credentials ?? [];

        return [
            'id' => $this->id,
            'provider' => $this->provider,
            'label' => $this->label,
            'is_enabled' => $this->is_enabled,
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
