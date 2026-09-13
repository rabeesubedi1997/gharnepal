<?php

namespace App\Http\Controllers\Api\V1\Account;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class PushSubscriptionController extends Controller
{
    /** Called by the frontend right after `pushManager.subscribe()` succeeds. */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'endpoint' => ['required', 'string'],
            'keys.p256dh' => ['required', 'string'],
            'keys.auth' => ['required', 'string'],
        ]);

        // Keyed on a hash of the endpoint (not the id) so re-subscribing
        // the same browser — e.g. after clearing the in-app "enabled"
        // preference and turning it back on — updates the existing row
        // instead of accumulating duplicates for one real subscription.
        $request->user()->pushSubscriptions()->updateOrCreate(
            ['endpoint_hash' => hash('sha256', $data['endpoint'])],
            [
                'endpoint' => $data['endpoint'],
                'p256dh' => $data['keys']['p256dh'],
                'auth' => $data['keys']['auth'],
            ],
        );

        return response()->json(['message' => 'Subscribed to push notifications.'], 201);
    }

    /** Called on "disable notifications" and right before the browser's own subscription is torn down. */
    public function destroy(Request $request): Response
    {
        $data = $request->validate(['endpoint' => ['required', 'string']]);

        $request->user()->pushSubscriptions()
            ->where('endpoint_hash', hash('sha256', $data['endpoint']))
            ->delete();

        return response()->noContent();
    }
}
