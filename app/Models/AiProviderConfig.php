<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AiProviderConfig extends Model
{
    protected $fillable = [
        'provider', 'label', 'is_enabled', 'credentials',
    ];

    protected function casts(): array
    {
        return [
            'is_enabled' => 'boolean',
            // Laravel's built-in encrypt/decrypt-on-the-fly cast (uses
            // APP_KEY) — same mechanism as PaymentGatewayConfig::credentials.
            'credentials' => 'encrypted:array',
        ];
    }

    public function credential(string $key): ?string
    {
        return $this->credentials[$key] ?? null;
    }
}
