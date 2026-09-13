<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Role extends Model
{
    // buyer, owner, agent, agency_admin, admin, super_admin
    public const BUYER = 'buyer';
    public const OWNER = 'owner';
    public const AGENT = 'agent';
    public const AGENCY_ADMIN = 'agency_admin';
    public const ADMIN = 'admin';
    // A super admin has every admin permission plus a few reserved to it
    // alone — see User::isAdmin()/isSuperAdmin() and Admin\UserController's
    // role-change guard. Not a separate silo: super_admin is a superset.
    public const SUPER_ADMIN = 'super_admin';

    protected $fillable = ['key', 'name'];

    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class);
    }
}
