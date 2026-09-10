<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'phone',
        'password',
        'locale',
        'status',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'phone_verified_at' => 'datetime',
            'last_active_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    public function roles(): BelongsToMany
    {
        return $this->belongsToMany(Role::class)->withTimestamps();
    }

    public function agencies(): BelongsToMany
    {
        return $this->belongsToMany(Agency::class, 'agency_user')
            ->withPivot('role_in_agency')
            ->withTimestamps();
    }

    public function savedSearches(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(SavedSearch::class);
    }

    public function calculatorScenarios(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(CostCalculatorScenario::class);
    }

    public function favorites(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Favorite::class);
    }

    public function verifications(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(UserVerification::class);
    }

    public function media(): \Illuminate\Database\Eloquent\Relations\MorphMany
    {
        return $this->morphMany(Media::class, 'mediable');
    }

    public function matchPreference(): \Illuminate\Database\Eloquent\Relations\HasOne
    {
        return $this->hasOne(MatchPreference::class);
    }

    public function matchResults(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(MatchResult::class);
    }

    public function isVerified(): bool
    {
        return $this->relationLoaded('verifications')
            ? $this->verifications->contains('status', 'approved')
            : $this->verifications()->where('status', 'approved')->exists();
    }

    public function hasRole(string $key): bool
    {
        return $this->relationLoaded('roles')
            ? $this->roles->contains('key', $key)
            : $this->roles()->where('key', $key)->exists();
    }

    public function isAdmin(): bool
    {
        return $this->hasRole(Role::ADMIN);
    }
}
