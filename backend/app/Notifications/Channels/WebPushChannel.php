<?php

namespace App\Notifications\Channels;

use App\Domain\Notifications\Contracts\PushSender;
use App\Models\PushSubscription;
use Illuminate\Notifications\Notification;

/**
 * A custom notification channel (returned by a notification's own via(), the
 * same as the built-in 'database'/'mail' channels) — any notification that
 * defines a toPush() method can opt into it. Fans out to every browser the
 * user has subscribed from (not just one).
 */
class WebPushChannel
{
    public function __construct(private readonly PushSender $sender) {}

    public function send(object $notifiable, Notification $notification): void
    {
        if (! method_exists($notification, 'toPush')) {
            return;
        }

        $payload = $notification->toPush($notifiable);
        if (! $payload) {
            return;
        }

        PushSubscription::where('user_id', $notifiable->id)
            ->get()
            ->each(fn (PushSubscription $subscription) => $this->sender->send($subscription, $payload));
    }
}
