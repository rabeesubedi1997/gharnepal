<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SeoCompetitorScan extends Model
{
    protected $fillable = [
        'page_key',
        'competitor_url',
        'scanned_title',
        'scanned_meta_description',
        'scanned_meta_keywords',
        'scanned_headings',
        'scanned_keywords',
        'scanned_og_image',
        'word_count',
        'status',
        'scanned_by',
    ];

    protected function casts(): array
    {
        return [
            'scanned_headings' => 'array',
            'scanned_keywords' => 'array',
        ];
    }

    public function scannedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'scanned_by');
    }
}
