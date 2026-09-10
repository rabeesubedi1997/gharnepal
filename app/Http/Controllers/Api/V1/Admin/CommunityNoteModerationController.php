<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\CommunityNoteResource;
use App\Models\CommunityNote;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class CommunityNoteModerationController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $status = $request->string('status', 'pending')->toString();

        $notes = CommunityNote::query()
            ->where('status', $status)
            ->with(['neighborhood', 'submittedBy'])
            ->latest()
            ->paginate(20);

        return CommunityNoteResource::collection($notes);
    }

    public function approve(Request $request, CommunityNote $note): CommunityNoteResource
    {
        $note->update(['status' => 'approved', 'moderated_by' => $request->user()->id, 'moderated_at' => now(), 'rejection_reason' => null]);

        return new CommunityNoteResource($note);
    }

    public function reject(Request $request, CommunityNote $note): CommunityNoteResource
    {
        $data = $request->validate(['reason' => ['required', 'string', 'max:500']]);

        $note->update([
            'status' => 'rejected',
            'moderated_by' => $request->user()->id,
            'moderated_at' => now(),
            'rejection_reason' => $data['reason'],
        ]);

        return new CommunityNoteResource($note);
    }
}
