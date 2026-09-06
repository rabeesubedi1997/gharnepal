<?php

namespace App\Http\Controllers\Api\V1\Messaging;

use App\Domain\Engagement\Services\MessagingService;
use App\Http\Controllers\Controller;
use App\Http\Resources\MessageResource;
use App\Models\Conversation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MessageController extends Controller
{
    public function __construct(private readonly MessagingService $messaging) {}

    public function store(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorize('view', $conversation);

        $data = $request->validate(['body' => ['required', 'string', 'max:2000']]);

        $message = $this->messaging->send($conversation, $request->user(), $data['body']);

        return (new MessageResource($message))->response()->setStatusCode(201);
    }
}
