<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PaymentTransaction extends Model
{
    public const STATUS_PENDING = 'pending';

    public const STATUS_COMPLETED = 'completed';

    public const STATUS_FAILED = 'failed';

    public const STATUS_REFUNDED = 'refunded';

    protected $fillable = [
        'user_id', 'property_listing_id', 'plan_key', 'plan_days',
        'amount', 'currency', 'gateway', 'gateway_config_id', 'gateway_reference', 'status', 'completed_at',
    ];

    protected function casts(): array
    {
        return [
            'user_id' => 'integer',
            'property_listing_id' => 'integer',
            'gateway_config_id' => 'integer',
            'plan_days' => 'integer',
            'amount' => 'decimal:2',
            'completed_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function propertyListing(): BelongsTo
    {
        return $this->belongsTo(PropertyListing::class);
    }

    public function gatewayConfig(): BelongsTo
    {
        return $this->belongsTo(PaymentGatewayConfig::class, 'gateway_config_id');
    }
}
