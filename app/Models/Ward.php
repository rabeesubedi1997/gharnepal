<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Ward extends Model
{
    protected $fillable = ['municipality_id', 'ward_number', 'name', 'centroid_lat', 'centroid_lng'];

    protected function casts(): array
    {
        return [
            'municipality_id' => 'integer',
            'ward_number' => 'integer',
            'centroid_lat' => 'float',
            'centroid_lng' => 'float',
        ];
    }

    public function municipality(): BelongsTo
    {
        return $this->belongsTo(Municipality::class);
    }

    public function neighborhoods(): HasMany
    {
        return $this->hasMany(Neighborhood::class);
    }
}
