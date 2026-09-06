<?php

namespace App\Http\Controllers\Api\V1\Account;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserVerificationResource;
use App\Models\UserVerification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class VerificationController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        return UserVerificationResource::collection(
            $request->user()->verifications()->latest()->get()
        );
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'type' => ['required', Rule::in(['identity', 'agent_license', 'agency_document'])],
            'document' => ['required', 'file', 'max:10240', 'mimes:jpg,jpeg,png,pdf'],
        ]);

        $user = $request->user();

        $path = $request->file('document')->store("verifications/{$user->id}", 'public');
        $media = $user->media()->create([
            'type' => 'document',
            'disk_path' => $path,
            'mime_type' => $request->file('document')->getMimeType(),
            'size_bytes' => $request->file('document')->getSize(),
            'uploaded_by' => $user->id,
        ]);

        $verification = UserVerification::create([
            'user_id' => $user->id,
            'type' => $data['type'],
            'document_media_id' => $media->id,
            'status' => 'pending',
        ]);

        return (new UserVerificationResource($verification->load('document')))->response()->setStatusCode(201);
    }
}
