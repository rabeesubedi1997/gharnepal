<?php

namespace App\Notifications;

use App\Models\PropertyListing;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class ListingRejectedNotification extends Notification
{
    use Queueable;

    public function __construct(public PropertyListing $listing, public string $reason) {}

    public function via(object $notifiable): array
    {
        return ['database'];
    }

    public function toArray(object $notifiable): array
    {
        return [
            'type' => 'listing_rejected',
            'listing_id' => $this->listing->id,
            'listing_slug' => $this->listing->slug,
            'title' => $this->listing->title,
            'reason' => $this->reason,
            'message' => "Your listing \"{$this->listing->title}\" was not approved: {$this->reason}",
        ];
    }
}
