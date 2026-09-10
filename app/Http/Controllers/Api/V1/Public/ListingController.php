<?php

namespace App\Http\Controllers\Api\V1\Public;

use App\Domain\Properties\Services\SimilarListingsFinder;
use App\Http\Controllers\Controller;
use App\Http\Resources\PropertyListingDetailResource;
use App\Http\Resources\PropertyListingSummaryResource;
use App\Models\PropertyListing;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class ListingController extends Controller
{
    public function __construct(private readonly SimilarListingsFinder $similarListingsFinder) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate([
            'purpose' => ['sometimes', Rule::in(['sale', 'rent'])],
            'property_type' => ['sometimes', Rule::in(['room', 'apartment', 'house', 'land', 'commercial'])],
            'min_price' => ['sometimes', 'numeric', 'min:0'],
            'max_price' => ['sometimes', 'numeric', 'min:0'],
            'bedrooms_min' => ['sometimes', 'integer', 'min:0'],
            'province_id' => ['sometimes', 'integer'],
            'district_id' => ['sometimes', 'integer'],
            'municipality_id' => ['sometimes', 'integer'],
            'ward_id' => ['sometimes', 'integer'],
            'neighborhood_id' => ['sometimes', 'integer'],
            'q' => ['sometimes', 'string', 'max:255'],
            'sort' => ['sometimes', Rule::in(['newest', 'price_asc', 'price_desc'])],
            'lalpurja_available' => ['sometimes', Rule::in(['yes', 'no', 'in_process', 'unknown'])],
            'road_access' => ['sometimes', 'boolean'],
        ]);

        $query = PropertyListing::query()
            ->where('status', PropertyListing::STATUS_PUBLISHED)
            ->whereHas('property', function ($q) use ($request) {
                if ($request->filled('property_type')) {
                    $q->where('property_type', $request->string('property_type'));
                }
                if ($request->filled('bedrooms_min')) {
                    $q->where('bedrooms', '>=', $request->integer('bedrooms_min'));
                }
                $q->whereHas('address', function ($a) use ($request) {
                    foreach (['province_id', 'district_id', 'municipality_id', 'ward_id', 'neighborhood_id'] as $field) {
                        if ($request->filled($field)) {
                            $a->where($field, $request->integer($field));
                        }
                    }
                });
                if ($request->filled('lalpurja_available') || $request->filled('road_access')) {
                    $q->whereHas('landProfile', function ($l) use ($request) {
                        if ($request->filled('lalpurja_available')) {
                            $l->where('lalpurja_available', $request->string('lalpurja_available'));
                        }
                        if ($request->filled('road_access')) {
                            $l->where('road_access', $request->boolean('road_access'));
                        }
                    });
                }
            })
            ->with(['property.address.municipality', 'property.address.ward', 'property.address.neighborhood', 'property.media', 'trustScore'])
            ->withCount(['ratings' => fn ($q) => $q->where('status', 'visible')])
            ->withAvg(['ratings' => fn ($q) => $q->where('status', 'visible')], 'score');

        if ($request->filled('purpose')) {
            $query->where('purpose', $request->string('purpose'));
        }
        if ($request->filled('min_price')) {
            $query->where('price', '>=', $request->float('min_price'));
        }
        if ($request->filled('max_price')) {
            $query->where('price', '<=', $request->float('max_price'));
        }
        if ($request->filled('q')) {
            $query->where('title', 'like', '%' . $request->string('q') . '%');
        }

        match ($request->string('sort')->toString()) {
            'price_asc' => $query->orderBy('price'),
            'price_desc' => $query->orderByDesc('price'),
            default => $query->latest('published_at'),
        };

        return PropertyListingSummaryResource::collection($query->paginate(12));
    }

    public function show(string $slug): PropertyListingDetailResource
    {
        $listing = PropertyListing::query()
            ->where('slug', $slug)
            ->where('status', PropertyListing::STATUS_PUBLISHED)
            ->with(['property.address.province', 'property.address.district', 'property.address.municipality', 'property.address.ward', 'property.address.neighborhood', 'property.media', 'property.owner.agencies', 'property.createdBy.agencies', 'property.landProfile.lalpurjaDocument', 'amenities', 'trustScore.breakdowns.factor', 'priceHistory'])
            ->withCount(['ratings' => fn ($q) => $q->where('status', 'visible')])
            ->withAvg(['ratings' => fn ($q) => $q->where('status', 'visible')], 'score')
            ->firstOrFail();

        $listing->increment('views_count');
        $listing->setRelation('similarListingsResults', $this->similarListingsFinder->find($listing));

        return new PropertyListingDetailResource($listing);
    }
}
