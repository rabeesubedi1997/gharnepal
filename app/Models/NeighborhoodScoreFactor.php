<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NeighborhoodScoreFactor extends Model
{
    protected $fillable = ['neighborhood_score_id', 'factor_key', 'score', 'data_source', 'notes'];

    protected function casts(): array
    {
        return [
            'neighborhood_score_id' => 'integer',
            'score' => 'integer',
        ];
    }

    public function neighborhoodScore(): BelongsTo
    {
        return $this->belongsTo(NeighborhoodScore::class);
    }
}
