<?php

namespace App\Http\Controllers\Api\V1\Owner;

use App\Http\Controllers\Controller;
use App\Http\Requests\Property\StoreMediaRequest;
use App\Http\Resources\MediaResource;
use App\Models\Media;
use App\Models\Property;
use Illuminate\Http\Response;

class MediaController extends Controller
{
    public function store(StoreMediaRequest $request, Property $property): \Illuminate\Http\JsonResponse
    {
        $this->authorize('update', $property);

        $file = $request->file('file');
        $path = $file->store("properties/{$property->id}", 'public');

        $media = $property->media()->create([
            'type' => $request->validated('type'),
            'disk_path' => $path,
            'mime_type' => $file->getMimeType(),
            'size_bytes' => $file->getSize(),
            'sort_order' => $property->media()->count(),
            'uploaded_by' => $request->user()->id,
        ]);

        return (new MediaResource($media))->response()->setStatusCode(201);
    }

    public function destroy(Property $property, Media $media): Response
    {
        $this->authorize('update', $property);

        abort_unless($media->mediable_type === Property::class && $media->mediable_id === $property->id, 404);

        \Illuminate\Support\Facades\Storage::disk('public')->delete($media->disk_path);
        $media->delete();

        return response()->noContent();
    }
}
