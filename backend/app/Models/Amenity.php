<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Amenity extends Model
{
    protected $fillable = ['key', 'name', 'name_ne', 'category', 'icon'];

    public function listings(): BelongsToMany
    {
        return $this->belongsToMany(PropertyListing::class, 'listing_amenities');
    }
}
