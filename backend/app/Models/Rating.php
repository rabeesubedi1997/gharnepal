<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class Rating extends Model
{
    protected $fillable = ['user_id', 'rateable_type', 'rateable_id', 'score', 'comment', 'status'];

    protected function casts(): array
    {
        return [
            'user_id' => 'integer',
            'rateable_id' => 'integer',
            'score' => 'integer',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function rateable(): MorphTo
    {
        return $this->morphTo();
    }
}
