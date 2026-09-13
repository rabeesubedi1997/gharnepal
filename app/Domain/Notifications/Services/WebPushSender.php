<?php

namespace App\Domain\Notifications\Services;

use App\Domain\Notifications\Contracts\PushSender;
use App\Models\PushSubscription;
use Minishlink\WebPush\Subscription;
use Minishlink\WebPush\WebPush;

/**
 * Real Web Push (RFC 8030/8291), not a stub — unlike the payment gateway,
 * this needs no external account: a self-generated VAPID keypair
 * (config('services.web_push')) plus the Push API is enough, and every
 * major browser's own push service (Chrome/Firefox/Edge) is the delivery
 * transport. Mobile (FCM) still needs a real Firebase project and is left
 * as a documented follow-up — see App\Domain\Notifications\Contracts\PushSender.
 */
class WebPushSender implements PushSender
{
    public function send(PushSubscription $subscription, array $payload): bool
    {
        $webPush = new WebPush([
            'VAPID' => [
                'subject' => config('app.frontend_url'),
                'publicKey' => config('services.web_push.vapid_public_key'),
                'privateKey' => config('services.web_push.vapid_private_key'),
            ],
        ]);

        $report = $webPush->sendOneNotification(
            Subscription::create([
                'endpoint' => $subscription->endpoint,
                'publicKey' => $subscription->p256dh,
                'authToken' => $subscription->auth,
            ]),
            json_encode($payload),
        );

        if ($report->isSuccess()) {
            return true;
        }

        // 404/410 means the browser itself dropped the subscription (the
        // user cleared site data, uninstalled, revoked permission, ...) —
        // clean it up so we stop retrying a subscription that will never
        // work again, rather than silently failing on it forever.
        $status = $report->getResponse()?->getStatusCode();
        if (in_array($status, [404, 410], true)) {
            $subscription->delete();
        }

        return false;
    }
}
