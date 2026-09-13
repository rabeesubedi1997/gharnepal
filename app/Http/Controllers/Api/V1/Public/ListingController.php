<?php

namespace App\Http\Controllers\Api\V1\Public;

use App\Domain\Properties\Services\ListingFilterQuery;
use App\Domain\Properties\Services\SimilarListingsFinder;
use App\Http\Controllers\Controller;
use App\Http\Resources\PropertyListingDetailResource;
use App\Http\Resources\PropertyListingSummaryResource;
use App\Models\PropertyListing;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Pagination\LengthAwarePaginator;
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
            'parking_type' => ['sometimes', Rule::in(['car', 'bike', 'both'])],
            'amenity_ids' => ['sometimes', 'array'],
            'amenity_ids.*' => ['integer', 'exists:amenities,id'],
            'polygon' => [
                'sometimes', 'string',
                function (string $attribute, mixed $value, \Closure $fail) {
                    if (! ListingFilterQuery::isValidPolygon($value)) {
                        $fail('Draw at least 3 points to search an area.');
                    }
                },
            ],
        ]);

        $query = PropertyListing::query()
            ->where('status', PropertyListing::STATUS_PUBLISHED)
            ->with(['property.address.municipality', 'property.address.ward', 'property.address.neighborhood', 'property.media', 'trustScore'])
            ->withCount(['ratings' => fn ($q) => $q->where('status', 'visible')])
            ->withAvg(['ratings' => fn ($q) => $q->where('status', 'visible')], 'score');

        $filters = $request->all();
        ListingFilterQuery::apply($query, $filters);

        match ($request->string('sort')->toString()) {
            'price_asc' => $query->orderBy('price'),
            'price_desc' => $query->orderByDesc('price'),
            default => $query->latest('published_at'),
        };

        $perPage = 12;

        if ($request->filled('polygon')) {
            // The bounding-box pre-filter in ListingFilterQuery::apply() has
            // already narrowed this to a small local area — a hand-drawn map
            // selection, never the whole country — so fetching a bounded
            // candidate set and refining/paginating in PHP is cheap. Exact
            // point-in-polygon isn't expressible in SQL portably (see
            // ListingFilterQuery::matchesPolygon's own docblock).
            $page = (int) $request->integer('page', 1);
            $candidates = $query->limit(500)->get();
            $matches = $candidates->filter(fn (PropertyListing $listing) => ListingFilterQuery::matchesPolygon(
                $filters,
                $listing->property?->address?->lat,
                $listing->property?->address?->lng,
            ))->values();

            $paginator = new LengthAwarePaginator(
                $matches->slice(($page - 1) * $perPage, $perPage)->values(),
                $matches->count(),
                $perPage,
                $page,
                ['path' => $request->url(), 'query' => $request->query()],
            );

            return PropertyListingSummaryResource::collection($paginator);
        }

        return PropertyListingSummaryResource::collection($query->paginate($perPage));
    }

    public function show(string $slug): PropertyListingDetailResource
    {
        $listing = PropertyListing::query()
            ->where('slug', $slug)
            ->where('status', PropertyListing::STATUS_PUBLISHED)
            ->with(['property.address.province', 'property.address.district', 'property.address.municipality', 'property.address.ward', 'property.address.neighborhood', 'property.media', 'property.owner.agencies', 'property.createdBy.agencies', 'property.landProfile.lalpurjaDocument', 'property.floorBreakdown', 'amenities', 'trustScore.breakdowns.factor', 'priceHistory'])
            ->withCount(['ratings' => fn ($q) => $q->where('status', 'visible')])
            ->withAvg(['ratings' => fn ($q) => $q->where('status', 'visible')], 'score')
            ->firstOrFail();

        $listing->increment('views_count');
        $listing->setRelation('similarListingsResults', $this->similarListingsFinder->find($listing));

        return new PropertyListingDetailResource($listing);
    }
}
