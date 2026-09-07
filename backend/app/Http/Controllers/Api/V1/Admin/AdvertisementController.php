<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Domain\Marketing\AdvertisementPlacement;
use App\Http\Controllers\Controller;
use App\Http\Resources\AdvertisementResource;
use App\Models\Advertisement;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class AdvertisementController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        return AdvertisementResource::collection(
            Advertisement::orderBy('placement')->orderBy('sort_order')->get()
        );
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'title' => ['nullable', 'string', 'max:255'],
            'subtitle' => ['nullable', 'string', 'max:500'],
            'link_url' => ['nullable', 'string', 'max:500'],
            'cta_label' => ['nullable', 'string', 'max:50'],
            'placement' => ['required', Rule::in(AdvertisementPlacement::keys())],
            'sort_order' => ['nullable', 'integer', 'min:0'],
            'is_active' => ['nullable', 'boolean'],
            'image' => ['required', 'file', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);

        $path = $request->file('image')->store('advertisements', 'public');

        $nextSortOrder = (Advertisement::where('placement', $data['placement'])->max('sort_order') ?? -1) + 1;

        $advertisement = Advertisement::create([
            ...collect($data)->except('image')->all(),
            'image_path' => $path,
            'sort_order' => $data['sort_order'] ?? $nextSortOrder,
            'is_active' => $request->boolean('is_active', true),
        ]);

        return (new AdvertisementResource($advertisement))->response()->setStatusCode(201);
    }

    public function update(Request $request, Advertisement $advertisement): AdvertisementResource
    {
        $data = $request->validate([
            'title' => ['nullable', 'string', 'max:255'],
            'subtitle' => ['nullable', 'string', 'max:500'],
            'link_url' => ['nullable', 'string', 'max:500'],
            'cta_label' => ['nullable', 'string', 'max:50'],
            'placement' => ['sometimes', Rule::in(AdvertisementPlacement::keys())],
            'sort_order' => ['sometimes', 'integer', 'min:0'],
            'is_active' => ['sometimes', 'boolean'],
            'image' => ['sometimes', 'file', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);

        if ($request->hasFile('image')) {
            Storage::disk('public')->delete($advertisement->image_path);
            $data['image_path'] = $request->file('image')->store('advertisements', 'public');
        }

        $advertisement->update(collect($data)->except('image')->all());

        return new AdvertisementResource($advertisement);
    }

    public function destroy(Advertisement $advertisement): Response
    {
        Storage::disk('public')->delete($advertisement->image_path);
        $advertisement->delete();

        return response()->noContent();
    }
}
