<?php

namespace App\Http\Controllers\Api\V1\Public;

use App\Domain\Assistant\Services\AssistantService;
use App\Http\Controllers\Controller;
use App\Http\Resources\PropertyListingSummaryResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AssistantController extends Controller
{
    public function __construct(private readonly AssistantService $assistant) {}

    public function chat(Request $request): JsonResponse
    {
        $data = $request->validate([
            'message' => ['required', 'string', 'max:500'],
            'conversation_id' => ['sometimes', 'nullable', 'integer'],
            'guest_token' => ['sometimes', 'nullable', 'string', 'max:64'],
        ]);

        $result = $this->assistant->handle(
            message: $data['message'],
            conversationId: $data['conversation_id'] ?? null,
            guestToken: $data['guest_token'] ?? null,
            userId: $request->user('sanctum')?->id,
        );

        return response()->json([
            'conversation_id' => $result['conversation_id'],
            'guest_token' => $result['guest_token'],
            'reply' => $result['reply'],
            'listings' => PropertyListingSummaryResource::collection($result['listings']),
            'filters_applied' => $result['filters_applied'],
        ]);
    }
}
