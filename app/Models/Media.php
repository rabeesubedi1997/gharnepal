<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class Media extends Model
{
    protected $fillable = [
        'mediable_type', 'mediable_id', 'type', 'disk_path', 'disk', 'mime_type',
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
        $disk = $this->disk ?: 'public';

        if ($disk === 'public') {
            return \Illuminate\Support\Facades\Storage::disk('public')->url($this->disk_path);
        }

        // Private disk (verification/land-title documents): a permanent public
        // URL would defeat the point, so hand back a short-lived signed one
        // instead — long enough for the page that requested it to load the
        // file, not so long that a leaked link stays useful.
        return \Illuminate\Support\Facades\Storage::disk($disk)->temporaryUrl(
            $this->disk_path,
            now()->addMinutes(10),
        );
    }
}
