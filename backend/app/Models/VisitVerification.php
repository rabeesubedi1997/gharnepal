<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VisitVerification extends Model
{
    protected $fillable = [
        'viewing_request_id', 'visited', 'matched_listing', 'price_accurate',
        'host_attended', 'documents_shown', 'overall_comment', 'submitted_by', 'submitted_at',
    ];

    protected function casts(): array
    {
        return [
            'viewing_request_id' => 'integer',
            'visited' => 'boolean',
            'matched_listing' => 'boolean',
            'price_accurate' => 'boolean',
            'host_attended' => 'boolean',
            'documents_shown' => 'boolean',
            'submitted_by' => 'integer',
            'submitted_at' => 'datetime',
        ];
    }

    public function viewingRequest(): BelongsTo
    {
        return $this->belongsTo(ViewingRequest::class);
    }

    public function submittedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'submitted_by');
    }
}
