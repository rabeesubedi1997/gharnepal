<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MatchPreference extends Model
{
    // Kept small and each backed by a real neighborhood score factor in
    // MatchScorer::LIFESTYLE_FACTOR_MAP — no tag exists here without a
    // genuine data source behind it.
    public const LIFESTYLE_TAGS = [
        'quiet',
        'safe',
        'family_friendly',
        'well_connected',
        'low_flood_risk',
        'good_internet',
        'vibrant_markets',
    ];

    protected $fillable = [
        'user_id',
        'purpose',
        'property_type',
        'budget_min',
        'budget_max',
        'min_bedrooms',
        'preferred_municipality_id',
        'work_lat',
        'work_lng',
        'work_location_label',
        'commute_limit_minutes',
        'family_size',
        'requires_school_nearby',
        'requires_parking',
        'investment_purpose',
        'lifestyle_tags',
    ];

    protected function casts(): array
    {
        return [
            'budget_min' => 'decimal:2',
            'budget_max' => 'decimal:2',
            'work_lat' => 'decimal:7',
            'work_lng' => 'decimal:7',
            'requires_school_nearby' => 'boolean',
            'requires_parking' => 'boolean',
            'investment_purpose' => 'boolean',
            'lifestyle_tags' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function preferredMunicipality(): BelongsTo
    {
        return $this->belongsTo(Municipality::class, 'preferred_municipality_id');
    }
}
