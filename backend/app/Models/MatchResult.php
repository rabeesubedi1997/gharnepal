<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MatchResult extends Model
{
    protected $table = 'match_results';

    protected $fillable = ['user_id', 'property_listing_id', 'score', 'reasons', 'computed_at'];

    protected function casts(): array
    {
        return [
            'user_id' => 'integer',
            'property_listing_id' => 'integer',
            'score' => 'integer',
            'reasons' => 'array',
            'computed_at' => 'datetime',
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
}
