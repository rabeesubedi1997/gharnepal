<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class FavoriteCollection extends Model
{
    protected $fillable = ['user_id', 'name', 'share_token'];

    protected static function booted(): void
    {
        static::creating(function (FavoriteCollection $collection) {
            $collection->share_token ??= self::uniqueShareToken();
        });
    }

    private static function uniqueShareToken(): string
    {
        do {
            $token = Str::random(22);
        } while (self::where('share_token', $token)->exists());

        return $token;
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function favorites(): HasMany
    {
        return $this->hasMany(Favorite::class);
    }
}
