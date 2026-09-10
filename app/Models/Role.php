<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Role extends Model
{
    // buyer, owner, agent, agency_admin, admin
    public const BUYER = 'buyer';
    public const OWNER = 'owner';
    public const AGENT = 'agent';
    public const AGENCY_ADMIN = 'agency_admin';
    public const ADMIN = 'admin';

    protected $fillable = ['key', 'name'];

    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class);
    }
}
