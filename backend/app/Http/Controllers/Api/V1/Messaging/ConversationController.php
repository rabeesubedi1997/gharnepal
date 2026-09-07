<?php

namespace App\Http\Controllers\Api\V1\Messaging;

use App\Domain\Engagement\Services\MessagingService;
use App\Http\Controllers\Controller;
use App\Http\Resources\ConversationResource;
use App\Models\Conversation;
use App\Models\PropertyListing;
use App\Models\PropertyRequest;
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
            ->with(['listing.property.media', 'propertyRequest', 'buyer', 'owner'])
            ->orderByDesc('last_message_at')
            ->paginate(20);

        return ConversationResource::collection($conversations);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'listing_id' => ['required_without:property_request_id', 'integer', 'exists:property_listings,id'],
            'property_request_id' => ['required_without:listing_id', 'integer', 'exists:property_requests,id'],
            'message' => ['required', 'string', 'max:2000'],
        ]);

        if (! empty($data['listing_id'])) {
            $listing = PropertyListing::findOrFail($data['listing_id']);
            $conversation = $this->messaging->startFromListing($listing, $request->user(), $data['message']);
        } else {
            $propertyRequest = PropertyRequest::findOrFail($data['property_request_id']);
            $conversation = $this->messaging->startFromPropertyRequest($propertyRequest, $request->user(), $data['message']);
        }

        return (new ConversationResource($conversation))->response()->setStatusCode(201);
    }

    public function show(Request $request, Conversation $conversation): ConversationResource
    {
        $this->authorize('view', $conversation);

        $this->messaging->markRead($conversation, $request->user());

        return new ConversationResource($conversation->load(['listing.property.media', 'propertyRequest', 'buyer', 'owner', 'messages' => fn ($q) => $q->oldest()->with('sender.roles')]));
    }
}
