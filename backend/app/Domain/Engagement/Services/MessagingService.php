<?php

namespace App\Domain\Engagement\Services;

use App\Domain\Trust\Services\TrustScoreCalculator;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\PropertyListing;
use App\Models\User;
use App\Notifications\NewMessageNotification;
use Illuminate\Validation\ValidationException;

class MessagingService
{
    public function __construct(private readonly TrustScoreCalculator $trustScoreCalculator) {}

    /** Starts a conversation with the listing's owner, or returns the existing one. */
    public function startFromListing(PropertyListing $listing, User $buyer, string $firstMessage): Conversation
    {
        $ownerId = $listing->property?->owner_user_id ?? $listing->created_by;

        if ($ownerId === $buyer->id) {
            throw ValidationException::withMessages(['listing' => "You can't message yourself about your own listing."]);
        }

        $conversation = Conversation::firstOrCreate(
            ['property_listing_id' => $listing->id, 'buyer_user_id' => $buyer->id],
            ['owner_user_id' => $ownerId, 'status' => 'open'],
        );

        $this->send($conversation, $buyer, $firstMessage);

        return $conversation->fresh(['listing.property.media', 'messages']);
    }

    public function send(Conversation $conversation, User $sender, string $body): Message
    {
        $message = $conversation->messages()->create([
            'sender_user_id' => $sender->id,
            'body' => $body,
        ]);

        $conversation->update(['last_message_at' => now()]);

        $recipient = $conversation->otherParticipant($sender);
        $recipient->notify(new NewMessageNotification($message));

        // Only an owner's reply moves the response-reliability factor.
        if ($conversation->owner_user_id === $sender->id && $conversation->listing?->status === PropertyListing::STATUS_PUBLISHED) {
            $this->trustScoreCalculator->recompute($conversation->listing);
        }

        return $message;
    }

    public function markRead(Conversation $conversation, User $reader): void
    {
        $conversation->messages()
            ->whereNull('read_at')
            ->where('sender_user_id', '!=', $reader->id)
            ->update(['read_at' => now()]);
    }
}
