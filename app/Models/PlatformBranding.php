<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

/**
 * Singleton settings row — always id 1. See the migration for why this
 * exists and what it can and can't do live.
 */
class PlatformBranding extends Model
{
    protected $table = 'platform_branding';

    protected $fillable = ['site_name', 'favicon_path', 'app_icon_path'];

    public static function current(): self
    {
        return static::query()->firstOrCreate(['id' => 1], ['site_name' => 'Ghar Nepal']);
    }

    public function faviconUrl(): ?string
    {
        return $this->favicon_path ? Storage::disk('public')->url($this->favicon_path) : null;
    }

    public function appIconUrl(): ?string
    {
        return $this->app_icon_path ? Storage::disk('public')->url($this->app_icon_path) : null;
    }
}
