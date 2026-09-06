<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ListingTrustScoreBreakdown extends Model
{
    protected $fillable = ['listing_trust_score_id', 'trust_score_factor_id', 'points_awarded', 'max_points', 'explanation'];

    public function trustScore(): BelongsTo
    {
        return $this->belongsTo(ListingTrustScore::class, 'listing_trust_score_id');
    }

    public function factor(): BelongsTo
    {
        return $this->belongsTo(TrustScoreFactor::class, 'trust_score_factor_id');
    }
}
