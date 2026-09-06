<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class ViewingRequest extends Model
{
    public const STATUS_REQUESTED = 'requested';
    public const STATUS_CONFIRMED = 'confirmed';
    public const STATUS_RESCHEDULED = 'rescheduled';
    public const STATUS_COMPLETED = 'completed';
    public const STATUS_CANCELLED = 'cancelled';
    public const STATUS_NO_SHOW = 'no_show';

    protected $fillable = [
        'property_listing_id', 'requester_user_id', 'host_user_id', 'conversation_id',
        'proposed_datetime', 'confirmed_datetime', 'status', 'notes',
    ];

    protected function casts(): array
    {
        return [
            'proposed_datetime' => 'datetime',
            'confirmed_datetime' => 'datetime',
        ];
    }

    public function listing(): BelongsTo
    {
        return $this->belongsTo(PropertyListing::class, 'property_listing_id');
    }

    public function requester(): BelongsTo
    {
        return $this->belongsTo(User::class, 'requester_user_id');
    }

    public function host(): BelongsTo
    {
        return $this->belongsTo(User::class, 'host_user_id');
    }

    public function visitVerification(): HasOne
    {
        return $this->hasOne(VisitVerification::class);
    }

    public function isParticipant(User $user): bool
    {
        return $this->requester_user_id === $user->id || $this->host_user_id === $user->id;
    }
}
