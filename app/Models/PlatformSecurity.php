<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Singleton settings row — always id 1. See the migration for why this
 * exists and the "never block on an unconfigured key" default.
 */
class PlatformSecurity extends Model
{
    protected $table = 'platform_security';

    protected $fillable = ['recaptcha_enabled', 'recaptcha_site_key', 'recaptcha_secret_key'];

    protected $casts = ['recaptcha_enabled' => 'boolean'];

    public static function current(): self
    {
        return static::query()->firstOrCreate(['id' => 1]);
    }

    /** Only turn the check on once every piece it needs is actually in place. */
    public function captchaIsActive(): bool
    {
        return $this->recaptcha_enabled && $this->recaptcha_site_key && $this->recaptcha_secret_key;
    }
}
