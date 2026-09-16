<?php

namespace App\Domain\Assistant\Services;

use App\Domain\Properties\Services\ListingFilterQuery;
use App\Http\Resources\PropertyListingSummaryResource;
use App\Models\Amenity;
use App\Models\PropertyListing;

/**
 * The three tools shared by every real-LLM driver (Claude, OpenAI, ...) —
 * so whichever provider an admin enables searches the exact same data the
 * rule-based PropertySearchParser and the public /listings page do. Each
 * driver wraps toolDefinitions()'s bare JSON-Schema shape in whatever
 * envelope its own SDK expects (Claude: inputSchema; OpenAI: function.parameters).
 */
class AssistantToolkit
{
    private const RESULTS_LIMIT = 5;

    /** @return array<int, array{name:string,description:string,parameters:array}> */
    public static function toolDefinitions(): array
    {
        return [
            [
                'name' => 'search_listings',
                'description' => 'Search published Ghar Nepal property listings. Always call this before describing any property — never invent listings, prices, or availability. Location filters take an id from resolve_location, not a place name.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'purpose' => ['type' => 'string', 'enum' => ['sale', 'rent'], 'description' => 'Buying/selling vs renting.'],
                        'property_type' => ['type' => 'string', 'enum' => ['room', 'apartment', 'house', 'land', 'commercial']],
                        'min_price' => ['type' => 'number', 'description' => 'NPR.'],
                        'max_price' => ['type' => 'number', 'description' => 'NPR.'],
                        'bedrooms_min' => ['type' => 'integer'],
                        'district_id' => ['type' => 'integer', 'description' => 'From resolve_location.'],
                        'municipality_id' => ['type' => 'integer', 'description' => 'From resolve_location.'],
                        'neighborhood_id' => ['type' => 'integer', 'description' => 'From resolve_location.'],
                        'amenity_ids' => ['type' => 'array', 'items' => ['type' => 'integer'], 'description' => 'Amenity ids — see the amenity catalog in your system prompt.'],
                        'q' => ['type' => 'string', 'description' => 'Free-text search over the listing title, for anything the structured filters above cannot express.'],
                    ],
                    'additionalProperties' => false,
                ],
            ],
            [
                'name' => 'resolve_location',
                'description' => 'Look up a place name (city, district, or neighborhood, in English or Nepali) against the real location data and get back candidate ids to use in search_listings. Returns several candidates when the name is ambiguous — ask the user to disambiguate rather than guessing.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'query' => ['type' => 'string', 'description' => 'The place name as the user wrote it.'],
                    ],
                    'required' => ['query'],
                    'additionalProperties' => false,
                ],
            ],
            [
                'name' => 'get_listing_detail',
                'description' => 'Fetch full detail for one listing by id, e.g. for a "tell me more about X" follow-up.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'id' => ['type' => 'integer'],
                    ],
                    'required' => ['id'],
                    'additionalProperties' => false,
                ],
            ],
        ];
    }

    /**
     * @param  array<string,mixed>  $filters
     * @return array{summary_for_model:string,listing_ids:list<int>}
     */
    public function searchListings(array $filters): array
    {
        $query = PropertyListing::query()
            ->where('status', PropertyListing::STATUS_PUBLISHED)
            ->with(['property.address.municipality', 'property.address.ward', 'property.address.neighborhood', 'property.media', 'trustScore'])
            ->withCount(['ratings' => fn ($q) => $q->where('status', 'visible')])
            ->withAvg(['ratings' => fn ($q) => $q->where('status', 'visible')], 'score');

        ListingFilterQuery::apply($query, $filters);

        $listings = $query->latest('published_at')->limit(self::RESULTS_LIMIT)->get();

        if ($listings->isEmpty()) {
            return ['summary_for_model' => 'No published listings matched these filters.', 'listing_ids' => []];
        }

        $lines = $listings->map(function (PropertyListing $listing) {
            $address = $listing->property?->address;
            $location = collect([$address?->neighborhood?->name, $address?->municipality?->name])->filter()->implode(', ');

            return sprintf(
                '#%d: "%s" — %s %s NPR %s%s in %s, %d bedroom(s)',
                $listing->id,
                $listing->title,
                $listing->purpose === 'rent' ? 'for rent' : 'for sale',
                $listing->purpose,
                number_format((float) $listing->price),
                $listing->price_period === 'monthly' ? '/month' : '',
                $location ?: 'unspecified area',
                $listing->property?->bedrooms ?? 0,
            );
        })->implode("\n");

        return ['summary_for_model' => $lines, 'listing_ids' => $listings->pluck('id')->all()];
    }

    /** @return array{candidates: list<array{type:string,id:int,label:string}>} */
    public function resolveLocation(string $query): array
    {
        $normalized = mb_strtolower(trim($query));
        $matches = [];

        foreach (PropertySearchParser::locationCandidates() as $candidate) {
            if (mb_strlen($candidate['name']) < 3) {
                continue;
            }
            if (mb_stripos($normalized, mb_strtolower($candidate['name'])) !== false || mb_stripos(mb_strtolower($candidate['name']), $normalized) !== false) {
                $matches[] = ['type' => $candidate['type'], 'id' => $candidate['id'], 'label' => $candidate['label']];
                if (count($matches) >= 8) {
                    break;
                }
            }
        }

        return ['candidates' => $matches];
    }

    /** @return array<string,mixed>|null */
    public function getListingDetail(int $id): ?array
    {
        $listing = PropertyListing::query()
            ->where('status', PropertyListing::STATUS_PUBLISHED)
            ->with(['property.address.municipality', 'property.address.ward', 'property.address.neighborhood', 'property.media', 'property.landProfile', 'amenities', 'trustScore'])
            ->withCount(['ratings' => fn ($q) => $q->where('status', 'visible')])
            ->withAvg(['ratings' => fn ($q) => $q->where('status', 'visible')], 'score')
            ->find($id);

        if (! $listing) {
            return null;
        }

        $data = (new PropertyListingSummaryResource($listing))->resolve();
        $data['description'] = $listing->description;
        $data['amenities'] = $listing->amenities->pluck('name')->all();

        return $data;
    }

    /** Amenity name -> id lookup, for a driver that wants to resolve amenity_ids itself rather than via a dedicated tool. */
    public function amenityCatalog(): array
    {
        return Amenity::query()->select('id', 'name')->get()->map(fn (Amenity $a) => ['id' => $a->id, 'name' => $a->name])->all();
    }
}
