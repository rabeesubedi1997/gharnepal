<?php

namespace Tests\Unit\Notifications;

use App\Domain\Notifications\Contracts\PushSender;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\PushSubscription;
use App\Models\User;
use App\Notifications\Channels\WebPushChannel;
use App\Notifications\NewMessageNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class WebPushChannelTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_sends_to_every_subscription_the_notifiable_has(): void
    {
        $user = User::factory()->create();
        $first = PushSubscription::create([
            'user_id' => $user->id, 'endpoint' => 'https://push.example/a', 'endpoint_hash' => hash('sha256', 'a'),
            'p256dh' => 'key-a', 'auth' => 'auth-a',
        ]);
        $second = PushSubscription::create([
            'user_id' => $user->id, 'endpoint' => 'https://push.example/b', 'endpoint_hash' => hash('sha256', 'b'),
            'p256dh' => 'key-b', 'auth' => 'auth-b',
        ]);

        $sender = new class implements PushSender {
            public array $calls = [];

            public function send(PushSubscription $subscription, array $payload): bool
            {
                $this->calls[] = [$subscription->id, $payload];

                return true;
            }
        };

        $conversation = Conversation::create(['buyer_user_id' => $user->id, 'owner_user_id' => $user->id, 'status' => 'open']);
        $message = Message::create(['conversation_id' => $conversation->id, 'sender_user_id' => $user->id, 'body' => 'Hello there']);
        $notification = new NewMessageNotification($message);

        (new WebPushChannel($sender))->send($user, $notification);

        $this->assertCount(2, $sender->calls);
        $this->assertSame([$first->id, $second->id], array_column($sender->calls, 0));
        $this->assertSame('New message from '.$user->name, $sender->calls[0][1]['title']);
    }

    public function test_it_does_nothing_for_a_notification_with_no_toPush_method(): void
    {
        $user = User::factory()->create();
        PushSubscription::create([
            'user_id' => $user->id, 'endpoint' => 'https://push.example/c', 'endpoint_hash' => hash('sha256', 'c'),
            'p256dh' => 'key-c', 'auth' => 'auth-c',
        ]);

        $sender = new class implements PushSender {
            public int $callCount = 0;

            public function send(PushSubscription $subscription, array $payload): bool
            {
                $this->callCount++;

                return true;
            }
        };

        $notificationWithoutPush = new class extends \Illuminate\Notifications\Notification {
            public function via($notifiable): array
            {
                return ['database'];
            }
        };

        (new WebPushChannel($sender))->send($user, $notificationWithoutPush);

        $this->assertSame(0, $sender->callCount);
    }
}
