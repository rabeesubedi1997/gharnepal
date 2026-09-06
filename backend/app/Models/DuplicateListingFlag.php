<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DuplicateListingFlag extends Model
{
    protected $fillable = [
        'property_listing_id', 'duplicate_of_listing_id', 'match_score',
        'match_reasons', 'status', 'reviewed_by',
    ];

    protected function casts(): array
    {
        return ['match_reasons' => 'array'];
    }

    public function listing(): BelongsTo
    {
        return $this->belongsTo(PropertyListing::class, 'property_listing_id');
    }

    public function duplicateOf(): BelongsTo
    {
        return $this->belongsTo(PropertyListing::class, 'duplicate_of_listing_id');
    }

    public function reviewedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }
}
