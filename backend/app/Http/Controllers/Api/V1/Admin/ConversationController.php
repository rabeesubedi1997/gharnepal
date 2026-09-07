<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\ConversationResource;
use App\Models\Conversation;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

/**
 * Read-only moderation view over buyer<->owner conversations. Admins never
 * post into a thread here — this exists so reports of abuse/spam/scams can
 * actually be investigated, which the platform had no way to do before.
 */
class ConversationController extends Controller
{
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
}
