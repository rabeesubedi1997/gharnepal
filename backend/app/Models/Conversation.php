<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Conversation extends Model
{
    protected $fillable = ['property_listing_id', 'property_request_id', 'buyer_user_id', 'owner_user_id', 'status', 'last_message_at'];

    protected function casts(): array
    {
        return [
            'property_listing_id' => 'integer',
            'property_request_id' => 'integer',
            'buyer_user_id' => 'integer',
            'owner_user_id' => 'integer',
            'last_message_at' => 'datetime',
        ];
    }

    public function listing(): BelongsTo
    {
        return $this->belongsTo(PropertyListing::class, 'property_listing_id');
    }

    public function propertyRequest(): BelongsTo
    {
        return $this->belongsTo(PropertyRequest::class);
    }

    public function buyer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'buyer_user_id');
    }

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_user_id');
    }

    public function messages(): HasMany
    {
        return $this->hasMany(Message::class);
    }

    public function isParticipant(User $user): bool
    {
        return $this->buyer_user_id === $user->id || $this->owner_user_id === $user->id;
    }

    public function otherParticipant(User $user): User
    {
        return $this->buyer_user_id === $user->id ? $this->owner : $this->buyer;
    }
}
