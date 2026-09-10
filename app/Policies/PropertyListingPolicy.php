<?php

namespace App\Policies;

use App\Models\PropertyListing;
use App\Models\User;

class PropertyListingPolicy
{
    public function update(User $user, PropertyListing $listing): bool
    {
        return $listing->property->isManagedBy($user) || $user->isAdmin();
    }

    public function delete(User $user, PropertyListing $listing): bool
    {
        return $listing->property->isManagedBy($user) || $user->isAdmin();
    }

    public function moderate(User $user, PropertyListing $listing): bool
    {
        return $user->isAdmin();
    }
}
