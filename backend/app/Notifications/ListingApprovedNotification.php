<?php

namespace App\Notifications;

use App\Models\PropertyListing;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class ListingApprovedNotification extends Notification
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
            'type' => 'listing_approved',
            'listing_id' => $this->listing->id,
            'listing_slug' => $this->listing->slug,
            'title' => $this->listing->title,
            'message' => "Your listing \"{$this->listing->title}\" is now live.",
        ];
    }
}
