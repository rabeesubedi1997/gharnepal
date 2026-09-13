<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PropertyFloor extends Model
{
    protected $fillable = ['property_id', 'label', 'area_sqm', 'description', 'sort_order'];

    protected function casts(): array
    {
        return [
            'property_id' => 'integer',
            'area_sqm' => 'float',
            'sort_order' => 'integer',
        ];
    }

    public function property(): BelongsTo
    {
        return $this->belongsTo(Property::class);
    }
}
