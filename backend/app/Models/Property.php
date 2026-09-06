<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Database\Eloquent\Relations\MorphOne;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Model;

class Property extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'owner_user_id',
        'property_type',
        'total_area_sqm',
        'total_area_unit_entered',
        'total_area_value_entered',
        'bedrooms',
        'bathrooms',
        'floors',
        'year_built',
        'parking_spaces',
        'parking_type',
        'is_furnished',
        'created_by',
    ];

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_user_id');
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function managers(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'property_managers')
            ->withPivot('relation')
            ->withTimestamps();
    }

    public function address(): MorphOne
    {
        return $this->morphOne(Address::class, 'addressable');
    }

    public function listings(): HasMany
    {
        return $this->hasMany(PropertyListing::class);
    }

    public function media(): MorphMany
    {
        return $this->morphMany(Media::class, 'mediable')->orderBy('sort_order');
    }

    public function landProfile(): HasOne
    {
        return $this->hasOne(LandProfile::class);
    }

    /** Is $user allowed to manage (edit/list) this property? */
    public function isManagedBy(User $user): bool
    {
        return $this->owner_user_id === $user->id
            || $this->created_by === $user->id
            || $this->managers()->where('users.id', $user->id)->exists();
    }
}
