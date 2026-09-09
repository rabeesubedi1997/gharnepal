<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Agency extends Model
{
    use SoftDeletes;

    protected $fillable = [
        'name',
        'slug',
        'logo_path',
        'description',
        'registration_number',
        'verified_at',
        'verified_by',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'verified_by' => 'integer',
            'verified_at' => 'datetime',
        ];
    }

    public function verifiedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'verified_by');
    }

    public function members(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'agency_user')
            ->withPivot('role_in_agency')
            ->withTimestamps();
    }

    public function isVerified(): bool
    {
        return $this->verified_at !== null;
    }
}
