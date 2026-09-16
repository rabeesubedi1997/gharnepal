<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AiConversation extends Model
{
    protected $fillable = [
        'user_id',
        'guest_token',
        'last_filters',
        'last_listing_ids',
    ];

    protected function casts(): array
    {
        return [
            'user_id' => 'integer',
            'last_filters' => 'array',
            'last_listing_ids' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function messages(): HasMany
    {
        return $this->hasMany(AiMessage::class);
    }
}
