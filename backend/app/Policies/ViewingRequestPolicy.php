<?php

namespace App\Policies;

use App\Models\User;
use App\Models\ViewingRequest;

class ViewingRequestPolicy
{
    public function view(User $user, ViewingRequest $viewingRequest): bool
    {
        return $viewingRequest->isParticipant($user);
    }

    public function update(User $user, ViewingRequest $viewingRequest): bool
    {
        return $viewingRequest->isParticipant($user);
    }

    /** Only the requester can submit visit-verification feedback. */
    public function verify(User $user, ViewingRequest $viewingRequest): bool
    {
        return $viewingRequest->requester_user_id === $user->id;
    }
}
