<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SeoPage extends Model
{
    protected $fillable = [
        'page_key',
        'page_type',
        'label',
        'meta_title',
        'meta_description',
        'meta_keywords',
        'og_image_url',
        'canonical_path',
        'robots_index',
        'robots_follow',
        'status',
        'updated_by',
    ];

    protected function casts(): array
    {
        return [
            'robots_index' => 'boolean',
            'robots_follow' => 'boolean',
            'updated_by' => 'integer',
        ];
    }

    public function updatedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    public function isLive(): bool
    {
        return $this->status === 'published';
    }
}
