<?php

namespace App\Policies;

use App\Models\Property;
use App\Models\User;

class PropertyPolicy
{
    public function view(User $user, Property $property): bool
    {
        return $property->isManagedBy($user) || $user->isAdmin();
    }

    public function update(User $user, Property $property): bool
    {
        return $property->isManagedBy($user) || $user->isAdmin();
    }

    public function delete(User $user, Property $property): bool
    {
        return $property->isManagedBy($user) || $user->isAdmin();
    }
}
