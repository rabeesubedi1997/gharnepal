<?php

namespace App\Notifications;

use App\Models\SavedSearch;
use App\Notifications\Channels\WebPushChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/**
 * Every other domain notification in this app (NewMessageNotification,
 * ListingApprovedNotification, ...) is 'database'-only — deliberately kept
 * that way since nothing else in the product needed a real inbox hit. A
 * saved-search alert is the exception: "tell me the moment/day/week a new
 * listing matches" only has value if it reaches the buyer outside the app,
 * the same way the password-reset flow already emails a real link — so this
 * one adds the 'mail' channel too (log-driver in dev, same as everything
 * else email-shaped here).
 */
class SavedSearchMatchNotification extends Notification
{
    use Queueable;

    /** @param array<int, \App\Models\PropertyListing> $listings */
    public function __construct(
        public readonly SavedSearch $savedSearch,
        public readonly array $listings,
    ) {}

    public function via(object $notifiable): array
    {
        return ['database', 'mail', WebPushChannel::class];
    }

    public function toArray(object $notifiable): array
    {
        $count = count($this->listings);

        return [
            'type' => 'saved_search_match',
            'saved_search_id' => $this->savedSearch->id,
            'saved_search_name' => $this->savedSearch->name,
            'listing_ids' => array_map(fn ($listing) => $listing->id, $this->listings),
            'count' => $count,
            'message' => $count === 1
                ? "1 new listing matches \"{$this->savedSearch->name}\""
                : "{$count} new listings match \"{$this->savedSearch->name}\"",
        ];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $count = count($this->listings);
        $name = $this->savedSearch->name;

        $mail = (new MailMessage)
            ->subject($count === 1 ? "New match for \"{$name}\"" : "{$count} new matches for \"{$name}\"")
            ->greeting('Hi '.$notifiable->name.',')
            ->line($count === 1
                ? "A new listing matches your saved search \"{$name}\":"
                : "{$count} new listings match your saved search \"{$name}\":");

        foreach (array_slice($this->listings, 0, 5) as $listing) {
            $mail->line('• '.$listing->title.' — Rs '.number_format((float) $listing->price));
        }

        if ($count > 5) {
            $mail->line('...and '.($count - 5).' more.');
        }

        return $mail
            ->action('View matching listings', config('app.frontend_url').'/search')
            ->line('You can change or turn off alerts for this search from your dashboard at any time.');
    }

    /** @return array{title: string, body: string, url: string} */
    public function toPush(object $notifiable): array
    {
        $count = count($this->listings);

        return [
            'title' => $count === 1 ? 'New match found' : "{$count} new matches found",
            'body' => "\"{$this->savedSearch->name}\" — ".($count === 1 ? $this->listings[0]->title : "{$count} new listings"),
            'url' => '/search',
        ];
    }
}
