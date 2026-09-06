<?php

namespace App\Notifications;

use App\Models\PropertyListing;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class FeaturedListingActivatedNotification extends Notification
{
    use Queueable;

    public function __construct(public PropertyListing $listing) {}

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toArray(object $notifiable): array
    {
        return [
            'type' => 'listing_featured',
            'listing_id' => $this->listing->id,
            'listing_slug' => $this->listing->slug,
            'title' => $this->listing->title,
            'message' => "\"{$this->listing->title}\" is now featured until "
                . $this->listing->featured_until?->toFormattedDateString() . '.',
        ];
    }
}
