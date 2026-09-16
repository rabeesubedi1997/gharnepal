<?php

namespace App\Domain\Assistant\Services;

use App\Domain\Properties\Services\ListingFilterQuery;
use App\Models\AiConversation;
use App\Models\AiMessage;
use App\Models\Amenity;
use App\Models\District;
use App\Models\Municipality;
use App\Models\Neighborhood;
use App\Models\PropertyListing;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;

/**
 * Orchestrates one assistant turn: parse the message (PropertySearchParser),
 * run the resolved filters through the same ListingFilterQuery the public
 * search page uses, template a reply, and persist the turn so the next
 * message in the conversation can build on it. No LLM anywhere in this path.
 */
class AssistantService
{
    private const RESULTS_LIMIT = 5;

    public function __construct(private readonly PropertySearchParser $parser) {}

    /**
     * @return array{conversation_id:int,guest_token:string,reply:string,listings:Collection<int,PropertyListing>,filters_applied:array<string,mixed>}
     */
    public function handle(string $message, ?int $conversationId, ?string $guestToken, ?int $userId): array
    {
        $guestToken = $guestToken ?: Str::random(32);
        $conversation = $this->resolveConversation($conversationId, $guestToken, $userId);

        $previousFilters = $conversation->last_filters ?? [];
        $previousListingIds = $conversation->last_listing_ids ?? [];

        $parsed = $this->parser->parse($message, $previousFilters, $previousListingIds);

        [$reply, $listings, $newFilters, $newListingIds] = match ($parsed['action']) {
            PropertySearchParser::ACTION_DETAIL => $this->handleDetail($parsed, $previousListingIds),
            PropertySearchParser::ACTION_CLARIFY => [$this->clarifyReply($parsed['language']), collect(), $previousFilters, $previousListingIds],
            default => $this->handleSearch($parsed),
        };

        AiMessage::create(['ai_conversation_id' => $conversation->id, 'role' => AiMessage::ROLE_USER, 'content' => $message]);
        AiMessage::create(['ai_conversation_id' => $conversation->id, 'role' => AiMessage::ROLE_ASSISTANT, 'content' => $reply]);

        $conversation->update([
            'guest_token' => $guestToken,
            'user_id' => $userId,
            'last_filters' => $newFilters,
            'last_listing_ids' => $newListingIds,
        ]);

        return [
            'conversation_id' => $conversation->id,
            'guest_token' => $guestToken,
            'reply' => $reply,
            'listings' => $listings,
            'filters_applied' => $this->describeFilters($newFilters),
        ];
    }

    private function resolveConversation(?int $conversationId, string $guestToken, ?int $userId): AiConversation
    {
        if ($conversationId) {
            $conversation = AiConversation::query()
                ->where('id', $conversationId)
                ->where(function ($q) use ($guestToken, $userId) {
                    $q->where('guest_token', $guestToken);
                    if ($userId) {
                        $q->orWhere('user_id', $userId);
                    }
                })
                ->first();

            if ($conversation) {
                return $conversation;
            }
        }

        return AiConversation::create(['guest_token' => $guestToken, 'user_id' => $userId]);
    }

    /** @return array{0:string,1:Collection<int,PropertyListing>,2:array<string,mixed>,3:list<int>} */
    private function handleSearch(array $parsed): array
    {
        $filters = $parsed['filters'];

        $query = PropertyListing::query()
            ->where('status', PropertyListing::STATUS_PUBLISHED)
            ->with(['property.address.municipality', 'property.address.ward', 'property.address.neighborhood', 'property.media', 'trustScore'])
            ->withCount(['ratings' => fn ($q) => $q->where('status', 'visible')])
            ->withAvg(['ratings' => fn ($q) => $q->where('status', 'visible')], 'score');

        ListingFilterQuery::apply($query, $filters);

        $listings = $query->latest('published_at')->limit(self::RESULTS_LIMIT)->get();

        $reply = $this->searchReply($parsed['language'], $filters, $listings->count());

        return [$reply, $listings, $filters, $listings->pluck('id')->all()];
    }

    /** @param  list<int>  $previousListingIds
     * @return array{0:string,1:Collection<int,PropertyListing>,2:array<string,mixed>,3:list<int>} */
    private function handleDetail(array $parsed, array $previousListingIds): array
    {
        $listingId = $parsed['detail_listing_id'];

        $listing = $listingId ? PropertyListing::query()
            ->where('status', PropertyListing::STATUS_PUBLISHED)
            ->with(['property.address.municipality', 'property.address.ward', 'property.address.neighborhood', 'property.media', 'trustScore'])
            ->withCount(['ratings' => fn ($q) => $q->where('status', 'visible')])
            ->withAvg(['ratings' => fn ($q) => $q->where('status', 'visible')], 'score')
            ->find($listingId) : null;

        $reply = $listing
            ? $this->detailReply($parsed['language'], $listing)
            : $this->invalidOrdinalReply($parsed['language']);

        return [$reply, $listing ? collect([$listing]) : collect(), $parsed['filters'], $previousListingIds];
    }

    private function clarifyReply(string $language): string
    {
        return $language === 'ne'
            ? 'माफ गर्नुहोस्, मैले राम्ररी बुझ्न सकिनँ। कृपया शहर/क्षेत्र, प्रकार (कोठा/फ्ल्याट/घर/जग्गा), र बजेट सहित लेख्नुहोस् — जस्तै "काठमाडौंमा २० हजारसम्मको कोठा चाहियो"।'
            : 'I couldn\'t quite tell what you\'re looking for — try including a city/area, a property type (room/flat/house/land), and your budget. For example: "a room in Kathmandu under NPR 20,000".';
    }

    private function detailReply(string $language, PropertyListing $listing): string
    {
        return $language === 'ne'
            ? "यहाँ थप जानकारी छ: {$listing->title}"
            : "Here's more about: {$listing->title}";
    }

    private function invalidOrdinalReply(string $language): string
    {
        return $language === 'ne'
            ? 'मसँग अघिल्लो नतिजाहरूको सूची छैन — कृपया फेरि खोज्नुहोस्।'
            : "I don't have a previous result list to reference — try searching again first.";
    }

    private function searchReply(string $language, array $filters, int $count): string
    {
        $described = $this->describeFilters($filters);
        $parts = array_values(array_filter([
            $described['purpose'] === 'rent' ? 'for rent' : ($described['purpose'] === 'sale' ? 'for sale' : null),
            $described['property_type'],
            $described['location'] ? 'in '.$described['location'] : null,
            $described['price_label'],
            $described['bedrooms_min'] ? $described['bedrooms_min'].'+ bedrooms' : null,
        ]));
        $summary = $parts !== [] ? implode(', ', $parts) : 'your search';

        if ($language === 'ne') {
            return $count > 0
                ? "{$summary} — {$count} वटा सूचीहरू भेटियौं। तलका उत्तम विकल्पहरू हेर्नुहोस्:"
                : "माफ गर्नुहोस्, {$summary} अनुसार कुनै सूची भेटिएन — बजेट वा क्षेत्र फराकिलो पार्नुहोस्।";
        }

        return $count > 0
            ? 'Found '.$count.' listing'.($count === 1 ? '' : 's')." for {$summary} — here are the top matches:"
            : "No listings found for {$summary} — try widening your budget or a nearby area.";
    }

    /** @return array{purpose:?string,property_type:?string,location:?string,price_label:?string,bedrooms_min:?int,amenities:list<string>} */
    private function describeFilters(array $filters): array
    {
        $location = null;
        if (isset($filters['neighborhood_id'])) {
            $location = Neighborhood::find($filters['neighborhood_id'])?->name;
        } elseif (isset($filters['municipality_id'])) {
            $municipalityName = Municipality::find($filters['municipality_id'])?->name;
            $location = $municipalityName ? PropertySearchParser::stripMunicipalitySuffix($municipalityName) : null;
        } elseif (isset($filters['district_id'])) {
            $location = District::find($filters['district_id'])?->name;
        }

        $amenities = [];
        if (! empty($filters['amenity_ids'])) {
            $amenities = Amenity::query()->whereIn('id', $filters['amenity_ids'])->pluck('name')->all();
        }

        $priceLabel = null;
        if (isset($filters['min_price']) && isset($filters['max_price'])) {
            $priceLabel = 'NPR '.number_format((float) $filters['min_price']).' – '.number_format((float) $filters['max_price']);
        } elseif (isset($filters['max_price'])) {
            $priceLabel = 'Under NPR '.number_format((float) $filters['max_price']);
        } elseif (isset($filters['min_price'])) {
            $priceLabel = 'Above NPR '.number_format((float) $filters['min_price']);
        }

        return [
            'purpose' => $filters['purpose'] ?? null,
            'property_type' => $filters['property_type'] ?? null,
            'location' => $location,
            'price_label' => $priceLabel,
            'bedrooms_min' => isset($filters['bedrooms_min']) ? (int) $filters['bedrooms_min'] : null,
            'amenities' => $amenities,
        ];
    }
}
