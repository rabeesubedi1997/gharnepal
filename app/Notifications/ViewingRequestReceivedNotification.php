<?php

namespace App\Notifications;

use App\Models\ViewingRequest;
use App\Notifications\Channels\WebPushChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/** Sent to the listing's host — or, for an agency listing, every member of
 * that agency (see LeadRoutingService) — the moment a buyer requests a
 * viewing. There was previously no notification here at all. */
class ViewingRequestReceivedNotification extends Notification
{
    use Queueable;

    public function __construct(public readonly ViewingRequest $viewingRequest) {}

    public function via(object $notifiable): array
    {
        return ['database', 'mail', WebPushChannel::class];
    }

    public function toArray(object $notifiable): array
    {
        $listing = $this->viewingRequest->listing;

        return [
            'type' => 'viewing_request_received',
            'viewing_request_id' => $this->viewingRequest->id,
            'listing_title' => $listing?->title,
            'requester_name' => $this->viewingRequest->requester?->name,
            'proposed_datetime' => $this->viewingRequest->proposed_datetime?->toIso8601String(),
            'message' => "{$this->viewingRequest->requester?->name} requested a viewing for \"{$listing?->title}\"",
        ];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $listing = $this->viewingRequest->listing;
        $when = $this->viewingRequest->proposed_datetime?->format('D, j M Y \a\t g:i A');

        $mail = (new MailMessage)
            ->subject('New viewing request — '.$listing?->title)
            ->greeting('Hi '.$notifiable->name.',')
            ->line("{$this->viewingRequest->requester?->name} requested a viewing of \"{$listing?->title}\" for {$when}.");

        if ($this->viewingRequest->notes) {
            $mail->line('Their note: "'.$this->viewingRequest->notes.'"');
        }

        return $mail
            ->action('Review the request', config('app.frontend_url').'/account/viewing-requests?as=host')
            ->line('Confirm, reschedule, or decline it from your dashboard.');
    }

    /** @return array{title: string, body: string, url: string} */
    public function toPush(object $notifiable): array
    {
        $listing = $this->viewingRequest->listing;

        return [
            'title' => 'New viewing request',
            'body' => "{$this->viewingRequest->requester?->name} wants to view \"{$listing?->title}\"",
            'url' => '/account/viewing-requests?as=host',
        ];
    }
}
