<?php

namespace App\Domain\Notifications\Contracts;

use App\Models\PushSubscription;

interface PushSender
{
    /**
     * @param  array{title: string, body: string, url?: string}  $payload
     * @return bool true if the push was accepted by the browser's push service.
     */
    public function send(PushSubscription $subscription, array $payload): bool;
}
