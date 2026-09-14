<?php

namespace App\Notifications;

use App\Models\PropertyListing;
use App\Notifications\Channels\WebPushChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/**
 * Fired the moment a newly published listing scores >= 50% against a
 * buyer's saved Smart Match preferences (SmartMatchAlertService, hooked
 * into PropertyListingService::approve() alongside the saved-search alert).
 * Same mail+push+database shape as SavedSearchMatchNotification — a strong
 * match only has value if it reaches the buyer outside the app.
 */
class MatchThresholdNotification extends Notification
{
    use Queueable;

    public function __construct(
        public readonly PropertyListing $listing,
        public readonly int $score,
    ) {}

    public function via(object $notifiable): array
    {
        return ['database', 'mail', WebPushChannel::class];
    }

    public function toArray(object $notifiable): array
    {
        return [
            'type' => 'smart_match_threshold',
            'listing_id' => $this->listing->id,
            'listing_slug' => $this->listing->slug,
            'listing_title' => $this->listing->title,
            'score' => $this->score,
            'message' => "{$this->score}% match: \"{$this->listing->title}\"",
        ];
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject("{$this->score}% match found — \"{$this->listing->title}\"")
            ->greeting('Hi '.$notifiable->name.',')
            ->line("A new listing matches {$this->score}% of your Smart Match preferences:")
            ->line('• '.$this->listing->title.' — Rs '.number_format((float) $this->listing->price))
            ->action('View this match', config('app.frontend_url').'/account/match-results')
            ->line('You can adjust your Smart Match preferences any time from your dashboard.');
    }

    /** @return array{title: string, body: string, url: string} */
    public function toPush(object $notifiable): array
    {
        return [
            'title' => "{$this->score}% match found",
            'body' => $this->listing->title,
            'url' => '/account/match-results',
        ];
    }
}
