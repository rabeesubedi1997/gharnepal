<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TrustScoreOverride extends Model
{
    protected $fillable = ['property_listing_id', 'admin_user_id', 'override_score', 'note', 'active'];

    protected function casts(): array
    {
        return [
            'property_listing_id' => 'integer',
            'admin_user_id' => 'integer',
            'override_score' => 'integer',
            'active' => 'boolean',
        ];
    }

    public function listing(): BelongsTo
    {
        return $this->belongsTo(PropertyListing::class, 'property_listing_id');
    }

    public function admin(): BelongsTo
    {
        return $this->belongsTo(User::class, 'admin_user_id');
    }
}
