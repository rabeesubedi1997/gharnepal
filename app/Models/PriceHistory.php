<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PriceHistory extends Model
{
    protected $table = 'price_history';

    protected $fillable = ['property_listing_id', 'price', 'changed_by', 'changed_at'];

    protected function casts(): array
    {
        return [
            'property_listing_id' => 'integer',
            'price' => 'decimal:2',
            'changed_by' => 'integer',
            'changed_at' => 'datetime',
        ];
    }

    public function listing(): BelongsTo
    {
        return $this->belongsTo(PropertyListing::class, 'property_listing_id');
    }
}
