<?php

namespace App\Notifications;

use App\Models\Message;
use App\Notifications\Channels\WebPushChannel;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;

class NewMessageNotification extends Notification
{
    use Queueable;

    public function __construct(public Message $message) {}

    public function via(object $notifiable): array
    {
        return ['database', WebPushChannel::class];
    }

    public function toArray(object $notifiable): array
    {
        return [
            'type' => 'new_message',
            'conversation_id' => $this->message->conversation_id,
            'sender_name' => $this->message->sender?->name,
            'preview' => str($this->message->body)->limit(80)->toString(),
            'message' => "New message from {$this->message->sender?->name}",
        ];
    }

    /** @return array{title: string, body: string, url: string} */
    public function toPush(object $notifiable): array
    {
        return [
            'title' => "New message from {$this->message->sender?->name}",
            'body' => str($this->message->body)->limit(100)->toString(),
            'url' => '/messages/'.$this->message->conversation_id,
        ];
    }
}
