<?php

namespace App\Domain\Engagement\Services;

use App\Models\PropertyListing;
use App\Models\User;
use App\Models\ViewingRequest;
use App\Notifications\ViewingRequestReceivedNotification;
use App\Notifications\ViewingRequestUpdatedNotification;
use Illuminate\Validation\ValidationException;

class ViewingRequestService
{
    public function __construct(private readonly LeadRoutingService $leadRouting) {}

    public function request(PropertyListing $listing, User $requester, string $proposedDatetime, ?string $notes): ViewingRequest
    {
        $host = $listing->property?->owner ?? $listing->property?->createdBy;
        $hostId = $host?->id ?? $listing->created_by;

        if ($hostId === $requester->id) {
            throw ValidationException::withMessages(['listing' => "You can't request a viewing of your own listing."]);
        }

        $viewingRequest = ViewingRequest::create([
            'property_listing_id' => $listing->id,
            'requester_user_id' => $requester->id,
            'host_user_id' => $hostId,
            'proposed_datetime' => $proposedDatetime,
            'notes' => $notes,
            'status' => ViewingRequest::STATUS_REQUESTED,
        ])->load('listing', 'requester');

        // This is a fresh lead — route it to the whole agency, if the host
        // belongs to one (see LeadRoutingService), not just the individual
        // host on record.
        $host ??= User::find($hostId);
        if ($host) {
            $this->leadRouting->recipientsFor($host)->each(
                fn (User $recipient) => $recipient->notify(new ViewingRequestReceivedNotification($viewingRequest)),
            );
        }

        return $viewingRequest;
    }

    public function confirm(ViewingRequest $viewingRequest, User $host, ?string $confirmedDatetime = null): ViewingRequest
    {
        $this->assertHost($viewingRequest, $host);
        $this->assertStatus($viewingRequest, [ViewingRequest::STATUS_REQUESTED, ViewingRequest::STATUS_RESCHEDULED]);

        $viewingRequest->update([
            'status' => ViewingRequest::STATUS_CONFIRMED,
            'confirmed_datetime' => $confirmedDatetime ?? $viewingRequest->proposed_datetime,
        ]);

        return $this->notifyCounterpart($viewingRequest, $host);
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

        return $this->notifyCounterpart($viewingRequest, $actor);
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

        return $this->notifyCounterpart($viewingRequest, $actor);
    }

    public function complete(ViewingRequest $viewingRequest, User $host): ViewingRequest
    {
        $this->assertHost($viewingRequest, $host);
        $this->assertStatus($viewingRequest, [ViewingRequest::STATUS_CONFIRMED]);

        $viewingRequest->update(['status' => ViewingRequest::STATUS_COMPLETED]);

        return $this->notifyCounterpart($viewingRequest, $host);
    }

    /** Notifies whichever participant did NOT just perform this action — see
     * ViewingRequestUpdatedNotification's own docblock for why this is a
     * single recipient rather than agency-wide. */
    private function notifyCounterpart(ViewingRequest $viewingRequest, User $actor): ViewingRequest
    {
        $viewingRequest = $viewingRequest->fresh(['listing', 'requester', 'host']);
        $counterpart = $viewingRequest->requester_user_id === $actor->id ? $viewingRequest->host : $viewingRequest->requester;
        $counterpart?->notify(new ViewingRequestUpdatedNotification($viewingRequest));

        return $viewingRequest;
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
