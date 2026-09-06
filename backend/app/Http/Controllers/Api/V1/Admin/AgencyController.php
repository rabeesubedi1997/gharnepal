<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\AgencyResource;
use App\Models\Agency;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class AgencyController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate([
            'status' => ['sometimes', Rule::in(['active', 'suspended', 'pending'])],
        ]);

        $agencies = Agency::query()
            ->withCount('members')
            ->when($request->filled('status'), fn ($q) => $q->where('status', $request->string('status')))
            ->latest()
            ->paginate(20);

        return AgencyResource::collection($agencies);
    }

    public function verify(Request $request, Agency $agency): AgencyResource
    {
        $agency->update([
            'status' => 'active',
            'verified_at' => now(),
            'verified_by' => $request->user()->id,
        ]);

        return new AgencyResource($agency->loadCount('members'));
    }

    /** Revokes verification and marks the agency suspended — used both to reject a pending application and to pull a previously verified agency. */
    public function suspend(Agency $agency): AgencyResource
    {
        $agency->update([
            'status' => 'suspended',
            'verified_at' => null,
        ]);

        return new AgencyResource($agency->loadCount('members'));
    }
}
