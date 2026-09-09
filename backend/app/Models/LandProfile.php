<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LandProfile extends Model
{
    protected $fillable = [
        'property_id', 'kitta_number', 'lalpurja_available', 'lalpurja_document_media_id',
        'road_access', 'road_width_meters', 'road_type',
        'water_access', 'electricity_access', 'drainage_access',
        'land_classification', 'flood_risk', 'landslide_risk', 'nearby_development_notes',
        'document_verification_status', 'verified_by', 'verified_at',
    ];

    protected function casts(): array
    {
        return [
            'property_id' => 'integer',
            'lalpurja_document_media_id' => 'integer',
            'road_access' => 'boolean',
            'electricity_access' => 'boolean',
            'road_width_meters' => 'decimal:2',
            'verified_by' => 'integer',
            'verified_at' => 'datetime',
        ];
    }

    public function property(): BelongsTo
    {
        return $this->belongsTo(Property::class);
    }

    public function lalpurjaDocument(): BelongsTo
    {
        return $this->belongsTo(Media::class, 'lalpurja_document_media_id');
    }

    public function verifiedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'verified_by');
    }

    /** How many of the "meaningful" fields have actually been filled in, for a completeness hint. */
    public function completenessPercent(): int
    {
        $fields = ['kitta_number', 'lalpurja_available', 'road_access', 'water_access', 'electricity_access', 'drainage_access', 'flood_risk', 'landslide_risk'];
        $filled = collect($fields)->filter(fn ($f) => ! in_array($this->{$f}, [null, 'unknown'], true))->count();

        return (int) round($filled / count($fields) * 100);
    }
}
