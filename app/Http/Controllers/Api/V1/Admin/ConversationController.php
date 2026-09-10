<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Domain\Engagement\Services\MessagingService;
use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\ConversationResource;
use App\Http\Resources\Admin\MessageResource;
use App\Models\Conversation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

/**
 * Moderation view over buyer<->owner conversations, so a reported spam/scam
 * thread can actually be investigated. Admins can also reply into a thread
 * — e.g. to answer a question or step into a dispute — which shows up for
 * both real participants like any other message, attributed to the admin's
 * name so it's not mistaken for the other party.
 */
class ConversationController extends Controller
{
    public function __construct(private readonly MessagingService $messaging) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate([
            'status' => ['sometimes', Rule::in(['open', 'closed'])],
            'q' => ['sometimes', 'string', 'max:255'],
        ]);

        $conversations = Conversation::query()
            ->when($request->filled('status'), fn ($q) => $q->where('status', $request->string('status')))
            ->when($request->filled('q'), function ($q) use ($request) {
                $term = '%'.$request->string('q').'%';
                $q->where(function ($sub) use ($term) {
                    $sub->whereHas('buyer', fn ($u) => $u->where('name', 'like', $term)->orWhere('email', 'like', $term))
                        ->orWhereHas('owner', fn ($u) => $u->where('name', 'like', $term)->orWhere('email', 'like', $term));
                });
            })
            ->withCount('messages')
            ->with(['buyer', 'owner', 'listing', 'propertyRequest', 'messages' => fn ($q) => $q->latest()->limit(1)])
            ->latest('last_message_at')
            ->paginate(25);

        return ConversationResource::collection($conversations);
    }

    public function show(Conversation $conversation): ConversationResource
    {
        return new ConversationResource(
            $conversation->load(['buyer', 'owner', 'listing', 'propertyRequest', 'messages.sender'])
        );
    }

    public function sendMessage(Request $request, Conversation $conversation): JsonResponse
    {
        $data = $request->validate(['body' => ['required', 'string', 'max:2000']]);

        $message = $this->messaging->send($conversation, $request->user(), $data['body']);

        return (new MessageResource($message->load('sender')))->response()->setStatusCode(201);
    }
}
