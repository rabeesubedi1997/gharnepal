<?php

namespace App\Http\Controllers\Api\V1\Public;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;

class PushConfigController extends Controller
{
    /** The frontend needs this to build the `applicationServerKey` for `pushManager.subscribe()`. Public — it's a public key, not a secret. */
    public function vapidPublicKey(): JsonResponse
    {
        return response()->json(['key' => config('services.web_push.vapid_public_key')]);
    }
}
