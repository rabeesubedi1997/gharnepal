<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ListingTrustScore extends Model
{
    protected $fillable = ['property_listing_id', 'computed_score', 'total_score', 'computed_at'];

    protected function casts(): array
    {
        return ['computed_at' => 'datetime'];
    }

    public function listing(): BelongsTo
    {
        return $this->belongsTo(PropertyListing::class, 'property_listing_id');
    }

    public function breakdowns(): HasMany
    {
        return $this->hasMany(ListingTrustScoreBreakdown::class);
    }
}
