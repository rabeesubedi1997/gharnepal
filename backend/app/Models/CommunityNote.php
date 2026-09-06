<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CommunityNote extends Model
{
    protected $fillable = [
        'neighborhood_id', 'submitted_by', 'category', 'body',
        'status', 'moderated_by', 'moderated_at', 'rejection_reason',
    ];

    protected function casts(): array
    {
        return ['moderated_at' => 'datetime'];
    }

    public function neighborhood(): BelongsTo
    {
        return $this->belongsTo(Neighborhood::class);
    }

    public function submittedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'submitted_by');
    }

    public function moderatedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'moderated_by');
    }
}
