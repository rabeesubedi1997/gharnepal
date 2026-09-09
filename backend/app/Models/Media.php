<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class Media extends Model
{
    protected $fillable = [
        'mediable_type', 'mediable_id', 'type', 'disk_path', 'mime_type',
        'size_bytes', 'width', 'height', 'sort_order', 'uploaded_by',
    ];

    protected function casts(): array
    {
        return [
            'mediable_id' => 'integer',
            'size_bytes' => 'integer',
            'width' => 'integer',
            'height' => 'integer',
            'sort_order' => 'integer',
            'uploaded_by' => 'integer',
        ];
    }

    public function mediable(): MorphTo
    {
        return $this->morphTo();
    }

    public function uploadedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'uploaded_by');
    }

    public function url(): string
    {
        return \Illuminate\Support\Facades\Storage::disk('public')->url($this->disk_path);
    }
}
