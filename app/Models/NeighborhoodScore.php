<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class NeighborhoodScore extends Model
{
    // The canonical list of factors admins can rate — kept here so seeders,
    // validation, and the frontend all agree on the same set.
    public const FACTORS = [
        'transport_access', 'schools', 'hospitals', 'markets', 'internet_availability',
        'road_quality', 'noise', 'safety', 'flood_risk', 'rental_demand', 'development_activity',
    ];

    protected $fillable = ['neighborhood_id', 'overall_score', 'source', 'computed_at'];

    protected function casts(): array
    {
        return [
            'neighborhood_id' => 'integer',
            'overall_score' => 'integer',
            'computed_at' => 'datetime',
        ];
    }

    public function neighborhood(): BelongsTo
    {
        return $this->belongsTo(Neighborhood::class);
    }

    public function factors(): HasMany
    {
        return $this->hasMany(NeighborhoodScoreFactor::class);
    }
}
