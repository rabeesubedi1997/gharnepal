<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PaymentGatewayConfig extends Model
{
    protected $fillable = [
        'provider', 'label', 'is_enabled', 'is_sandbox', 'sort_order', 'credentials', 'instructions',
    ];

    protected function casts(): array
    {
        return [
            'is_enabled' => 'boolean',
            'is_sandbox' => 'boolean',
            'sort_order' => 'integer',
            // Laravel's built-in encrypt/decrypt-on-the-fly cast (uses APP_KEY)
            // — real merchant secrets never sit in the database in plaintext.
            'credentials' => 'encrypted:array',
        ];
    }

    public function credential(string $key): ?string
    {
        return $this->credentials[$key] ?? null;
    }
}
