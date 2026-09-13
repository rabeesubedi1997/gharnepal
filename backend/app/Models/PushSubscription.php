<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/** A single browser/device's Web Push subscription — a user can have several (one per browser they enabled it in). */
class PushSubscription extends Model
{
    protected $fillable = ['user_id', 'endpoint', 'endpoint_hash', 'p256dh', 'auth'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
