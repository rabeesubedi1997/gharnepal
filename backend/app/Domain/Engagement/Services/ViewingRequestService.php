<?php

namespace App\Domain\Engagement\Services;

use App\Models\PropertyListing;
use App\Models\User;
use App\Models\ViewingRequest;
use Illuminate\Validation\ValidationException;

class ViewingRequestService
{
    public function request(PropertyListing $listing, User $requester, string $proposedDatetime, ?string $notes): ViewingRequest
    {
        $hostId = $listing->property?->owner_user_id ?? $listing->created_by;

        if ($hostId === $requester->id) {
            throw ValidationException::withMessages(['listing' => "You can't request a viewing of your own listing."]);
        }

        return ViewingRequest::create([
            'property_listing_id' => $listing->id,
            'requester_user_id' => $requester->id,
            'host_user_id' => $hostId,
            'proposed_datetime' => $proposedDatetime,
            'notes' => $notes,
            'status' => ViewingRequest::STATUS_REQUESTED,
        ]);
    }

    public function confirm(ViewingRequest $viewingRequest, User $host, ?string $confirmedDatetime = null): ViewingRequest
    {
        $this->assertHost($viewingRequest, $host);
        $this->assertStatus($viewingRequest, [ViewingRequest::STATUS_REQUESTED, ViewingRequest::STATUS_RESCHEDULED]);

        $viewingRequest->update([
            'status' => ViewingRequest::STATUS_CONFIRMED,
            'confirmed_datetime' => $confirmedDatetime ?? $viewingRequest->proposed_datetime,
        ]);

        return $viewingRequest->fresh();
    }

    public function reschedule(ViewingRequest $viewingRequest, User $actor, string $newDatetime): ViewingRequest
    {
        if (! $viewingRequest->isParticipant($actor)) {
            throw ValidationException::withMessages(['viewing' => 'Not authorized.']);
        }
        $this->assertStatus($viewingRequest, [ViewingRequest::STATUS_REQUESTED, ViewingRequest::STATUS_CONFIRMED]);

        $viewingRequest->update([
            'status' => ViewingRequest::STATUS_RESCHEDULED,
            'proposed_datetime' => $newDatetime,
            'confirmed_datetime' => null,
        ]);

        return $viewingRequest->fresh();
    }

    public function cancel(ViewingRequest $viewingRequest, User $actor): ViewingRequest
    {
        if (! $viewingRequest->isParticipant($actor)) {
            throw ValidationException::withMessages(['viewing' => 'Not authorized.']);
        }
        $this->assertStatus($viewingRequest, [
            ViewingRequest::STATUS_REQUESTED, ViewingRequest::STATUS_CONFIRMED, ViewingRequest::STATUS_RESCHEDULED,
        ]);

        $viewingRequest->update(['status' => ViewingRequest::STATUS_CANCELLED]);

        return $viewingRequest->fresh();
    }

    public function complete(ViewingRequest $viewingRequest, User $host): ViewingRequest
    {
        $this->assertHost($viewingRequest, $host);
        $this->assertStatus($viewingRequest, [ViewingRequest::STATUS_CONFIRMED]);

        $viewingRequest->update(['status' => ViewingRequest::STATUS_COMPLETED]);

        return $viewingRequest->fresh();
    }

    private function assertHost(ViewingRequest $viewingRequest, User $user): void
    {
        if ($viewingRequest->host_user_id !== $user->id) {
            throw ValidationException::withMessages(['viewing' => 'Only the host can do that.']);
        }
    }

    private function assertStatus(ViewingRequest $viewingRequest, array $allowed): void
    {
        if (! in_array($viewingRequest->status, $allowed, true)) {
            throw ValidationException::withMessages(['status' => "Cannot do that from status [{$viewingRequest->status}]."]);
        }
    }
}
