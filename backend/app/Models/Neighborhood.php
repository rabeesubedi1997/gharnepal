<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Neighborhood extends Model
{
    protected $fillable = [
        'ward_id',
        'name',
        'name_ne',
        'boundary_geojson',
        'centroid_lat',
        'centroid_lng',
        'is_curated',
    ];

    protected function casts(): array
    {
        return [
            'ward_id' => 'integer',
            'centroid_lat' => 'float',
            'centroid_lng' => 'float',
            'is_curated' => 'boolean',
        ];
    }

    public function ward(): BelongsTo
    {
        return $this->belongsTo(Ward::class);
    }

    public function score(): HasOne
    {
        return $this->hasOne(NeighborhoodScore::class);
    }

    public function pois(): HasMany
    {
        return $this->hasMany(NeighborhoodPoi::class);
    }

    public function communityNotes(): HasMany
    {
        return $this->hasMany(CommunityNote::class);
    }
}
