<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NeighborhoodScoreFactor extends Model
{
    protected $fillable = ['neighborhood_score_id', 'factor_key', 'score', 'data_source', 'notes'];

    public function neighborhoodScore(): BelongsTo
    {
        return $this->belongsTo(NeighborhoodScore::class);
    }
}
