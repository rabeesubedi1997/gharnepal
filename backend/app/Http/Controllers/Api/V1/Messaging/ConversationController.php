<?php

namespace App\Http\Controllers\Api\V1\Messaging;

use App\Domain\Engagement\Services\MessagingService;
use App\Http\Controllers\Controller;
use App\Http\Resources\ConversationResource;
use App\Models\Conversation;
use App\Models\PropertyListing;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class ConversationController extends Controller
{
    public function __construct(private readonly MessagingService $messaging) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $user = $request->user();

        $conversations = Conversation::query()
            ->where(fn ($q) => $q->where('buyer_user_id', $user->id)->orWhere('owner_user_id', $user->id))
            ->withCount(['messages as unread_messages_count' => fn ($q) => $q->whereNull('read_at')->where('sender_user_id', '!=', $user->id)])
            ->with(['listing.property.media', 'buyer', 'owner'])
            ->orderByDesc('last_message_at')
            ->paginate(20);

        return ConversationResource::collection($conversations);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'listing_id' => ['required', 'integer', 'exists:property_listings,id'],
            'message' => ['required', 'string', 'max:2000'],
        ]);

        $listing = PropertyListing::findOrFail($data['listing_id']);
        $conversation = $this->messaging->startFromListing($listing, $request->user(), $data['message']);

        return (new ConversationResource($conversation))->response()->setStatusCode(201);
    }

    public function show(Request $request, Conversation $conversation): ConversationResource
    {
        $this->authorize('view', $conversation);

        $this->messaging->markRead($conversation, $request->user());

        return new ConversationResource($conversation->load(['listing.property.media', 'buyer', 'owner', 'messages' => fn ($q) => $q->oldest()]));
    }
}
