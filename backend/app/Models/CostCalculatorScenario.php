<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CostCalculatorScenario extends Model
{
    protected $fillable = ['user_id', 'property_listing_id', 'type', 'name', 'inputs', 'computed_result'];

    protected function casts(): array
    {
        return [
            'user_id' => 'integer',
            'property_listing_id' => 'integer',
            'inputs' => 'array',
            'computed_result' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function listing(): BelongsTo
    {
        return $this->belongsTo(PropertyListing::class, 'property_listing_id');
    }
}
