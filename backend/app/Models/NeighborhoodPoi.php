<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NeighborhoodPoi extends Model
{
    protected $fillable = ['neighborhood_id', 'poi_type', 'name', 'lat', 'lng', 'added_by', 'verified'];

    protected function casts(): array
    {
        return ['verified' => 'boolean'];
    }

    public function neighborhood(): BelongsTo
    {
        return $this->belongsTo(Neighborhood::class);
    }

    public function addedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'added_by');
    }
}
