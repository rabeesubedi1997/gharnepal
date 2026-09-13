<?php

namespace App\Policies;

use App\Models\FavoriteCollection;
use App\Models\User;

class FavoriteCollectionPolicy
{
    public function update(User $user, FavoriteCollection $collection): bool
    {
        return $user->id === $collection->user_id;
    }

    public function delete(User $user, FavoriteCollection $collection): bool
    {
        return $user->id === $collection->user_id;
    }
}
