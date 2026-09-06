<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Province extends Model
{
    protected $fillable = ['name', 'name_ne', 'code'];

    public function districts(): HasMany
    {
        return $this->hasMany(District::class);
    }
}
