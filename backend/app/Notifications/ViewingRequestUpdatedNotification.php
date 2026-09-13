<?php

namespace App\Notifications;

use App\Models\ViewingRequest;
use App\Notifications\Channels\WebPushChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/**
 * Sent to whichever single participant did NOT trigger the status change —
 * a host confirming a request notifies the requester, a requester
 * cancelling notifies the host, and so on. Deliberately not agency-wide
 * (unlike ViewingRequestReceivedNotification): this is an update to an
 * already-claimed lead between two specific people, not a fresh one.
 */
class ViewingRequestUpdatedNotification extends Notification
{
    use Queueable;

    public function __construct(public readonly ViewingRequest $viewingRequest) {}

    public function via(object $notifiable): array
    {
        return ['database', 'mail', WebPushChannel::class];
    }

    private function summary(): string
    {
        $listing = $this->viewingRequest->listing?->title;

        return match ($this->viewingRequest->status) {
            ViewingRequest::STATUS_CONFIRMED => "Your viewing of \"{$listing}\" was confirmed",
            ViewingRequest::STATUS_RESCHEDULED => "The viewing of \"{$listing}\" was rescheduled",
            ViewingRequest::STATUS_CANCELLED => "The viewing of \"{$listing}\" was cancelled",
            ViewingRequest::STATUS_COMPLETED => "The viewing of \"{$listing}\" was marked completed",
            default => "The viewing of \"{$listing}\" was updated",
        };
    }

    public function toArray(object $notifiable): array
    {
        return [
            'type' => 'viewing_request_updated',
            'viewing_request_id' => $this->viewingRequest->id,
            'status' => $this->viewingRequest->status,
            'listing_title' => $this->viewingRequest->listing?->title,
            'message' => $this->summary(),
        ];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $when = $this->viewingRequest->confirmed_datetime?->format('D, j M Y \a\t g:i A')
            ?? $this->viewingRequest->proposed_datetime?->format('D, j M Y \a\t g:i A');

        return (new MailMessage)
            ->subject($this->summary())
            ->greeting('Hi '.$notifiable->name.',')
            ->line($this->summary().($when ? " — {$when}." : '.'))
            ->action('View details', config('app.frontend_url').'/account/viewing-requests');
    }

    /** @return array{title: string, body: string, url: string} */
    public function toPush(object $notifiable): array
    {
        return [
            'title' => 'Viewing request update',
            'body' => $this->summary(),
            'url' => '/account/viewing-requests',
        ];
    }
}
