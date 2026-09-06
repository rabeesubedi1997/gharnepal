<?php

namespace App\Http\Controllers\Api\V1\Owner;

use App\Http\Controllers\Controller;
use App\Http\Requests\Property\StoreLandProfileRequest;
use App\Http\Resources\LandProfileResource;
use App\Models\LandProfile;
use App\Models\Property;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class LandProfileController extends Controller
{
    public function show(Property $property): LandProfileResource
    {
        $this->authorize('view', $property);

        return new LandProfileResource($property->landProfile()->firstOrCreate([]));
    }

    public function store(StoreLandProfileRequest $request, Property $property): LandProfileResource
    {
        $this->authorize('update', $property);

        if ($property->property_type !== 'land') {
            throw ValidationException::withMessages(['property' => 'Only land listings have a due-diligence profile.']);
        }

        $profile = $property->landProfile()->updateOrCreate([], $request->validated());

        return new LandProfileResource($profile);
    }

    public function uploadDocument(Request $request, Property $property): LandProfileResource
    {
        $this->authorize('update', $property);

        $request->validate(['file' => ['required', 'file', 'max:10240', 'mimes:jpg,jpeg,png,pdf']]);

        $path = $request->file('file')->store("properties/{$property->id}/land-documents", 'public');
        $media = $property->media()->create([
            'type' => 'document',
            'disk_path' => $path,
            'mime_type' => $request->file('file')->getMimeType(),
            'size_bytes' => $request->file('file')->getSize(),
            'uploaded_by' => $request->user()->id,
        ]);

        $profile = $property->landProfile()->updateOrCreate([], ['lalpurja_document_media_id' => $media->id]);

        return new LandProfileResource($profile->load('lalpurjaDocument'));
    }

    /** Admin-only: marks how thoroughly the submitted land documents were reviewed. */
    public function verify(Request $request, Property $property): LandProfileResource
    {
        $data = $request->validate([
            'document_verification_status' => ['required', 'in:unverified,partial,verified'],
        ]);

        $profile = $property->landProfile()->firstOrCreate([]);
        $profile->update([
            ...$data,
            'verified_by' => $request->user()->id,
            'verified_at' => now(),
        ]);

        return new LandProfileResource($profile->load('lalpurjaDocument'));
    }
}
