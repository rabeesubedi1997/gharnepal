<?php

namespace App\Domain\Assistant\Services;

use App\Models\Amenity;
use App\Models\District;
use App\Models\Municipality;
use App\Models\Neighborhood;
use Illuminate\Support\Facades\Cache;

/**
 * Turns a free-text message into the same filter shape ListingFilterQuery::apply()
 * already expects — no LLM involved, just keyword/synonym dictionaries, regex for
 * numbers, and substring matching against real location/amenity names already in
 * the database. See feedback-no-paid-ai-apis in project memory for why.
 */
class PropertySearchParser
{
    public const ACTION_SEARCH = 'search';

    public const ACTION_DETAIL = 'detail';

    public const ACTION_CLARIFY = 'clarify';

    public const LANG_ENGLISH = 'en';

    public const LANG_NEPALI = 'ne';

    public const LANG_NEPALI_LATIN = 'ne_latin';

    // Romanized and Devanagari terms mixed together — both scripts get a
    // real match, not just the reply-template language.
    private const PROPERTY_TYPE_SYNONYMS = [
        'room' => 'room', 'rooms' => 'room', 'kotha' => 'room', 'कोठा' => 'room',
        'flat' => 'apartment', 'flats' => 'apartment', 'apartment' => 'apartment', 'apartments' => 'apartment', 'appartment' => 'apartment', 'फ्ल्याट' => 'apartment',
        'house' => 'house', 'houses' => 'house', 'ghar' => 'house', 'bungalow' => 'house', 'villa' => 'house', 'घर' => 'house',
        'land' => 'land', 'jagga' => 'land', 'plot' => 'land', 'plots' => 'land', 'जग्गा' => 'land', 'जमिन' => 'land',
        'shop' => 'commercial', 'shops' => 'commercial', 'pasal' => 'commercial', 'office' => 'commercial', 'offices' => 'commercial', 'commercial' => 'commercial', 'पसल' => 'commercial', 'कार्यालय' => 'commercial',
    ];

    private const PURPOSE_SYNONYMS = [
        'rent' => 'rent', 'rental' => 'rent', 'renting' => 'rent', 'bhada' => 'rent', 'bhadama' => 'rent', 'lease' => 'rent', 'भाडा' => 'rent', 'भाडामा' => 'rent',
        'sale' => 'sale', 'sell' => 'sale', 'selling' => 'sale', 'buy' => 'sale', 'buying' => 'sale', 'purchase' => 'sale', 'bikri' => 'sale', 'kinne' => 'sale', 'बिक्री' => 'sale', 'किन्ने' => 'sale',
    ];

    // A handful of common English spelling variants for major cities — the
    // DB's own name/name_ne columns already cover exact names, this just
    // catches the informal spellings people actually type.
    private const LOCATION_ALIASES = [
        'katmandu' => 'kathmandu', 'ktm' => 'kathmandu', 'kthmandu' => 'kathmandu',
        'patan' => 'lalitpur',
        'pokhra' => 'pokhara',
    ];

    private const AMENITY_SYNONYMS = [
        'parking' => 'parking', 'car parking' => 'parking',
        'wifi' => 'wifi', 'wi-fi' => 'wifi', 'internet' => 'wifi',
        'lift' => 'lift', 'elevator' => 'lift',
        'security' => 'security', 'guard' => 'security',
        'garden' => 'garden',
        'furnished' => 'furnished',
    ];

    private const RESET_KEYWORDS = ['start over', 'new search', 'reset', 'forget that', 'clear filters'];

    private const CHEAPER_KEYWORDS = ['cheaper', 'less expensive', 'lower budget', 'lower price', 'reduce budget', 'more affordable'];

    private const PRICIER_KEYWORDS = ['pricier', 'more expensive', 'higher budget', 'bigger budget', 'increase budget'];

    private const MORE_BEDROOMS_KEYWORDS = ['more bedrooms', 'bigger', 'more rooms', 'more space'];

    // Nepali typed in Latin script (no Devanagari keyboard) is extremely
    // common — these are function/particle words that rarely appear in an
    // English sentence, so a handful of hits is a solid signal without a
    // real language-detection model. Heuristic, not exhaustive.
    private const ROMANIZED_NEPALI_MARKERS = [
        'chaiyo', 'chahiyo', 'malai', 'vaneko', 'khojeko', 'khojirako', 'khojdai',
        'hunxa', 'huncha', 'parcha', 'paryo', 'vayo', 'vaye', 'haina', 'chha', 'xa',
        'tapai', 'tapaiko', 'hamro', 'mero', 'yo', 'tyo', 'kaha', 'kahan', 'kati', 'kun',
    ];

    /**
     * @param  array<string,mixed>  $previousFilters
     * @param  array<int,int>  $previousListingIds
     * @return array{action:string,filters:array<string,mixed>,detail_listing_id:?int,language:string,matched_location_label:?string}
     */
    public function parse(string $message, array $previousFilters, array $previousListingIds): array
    {
        $language = $this->detectLanguage($message);
        $normalized = $this->normalize($message);

        $ordinal = $this->extractOrdinalReference($normalized);
        if ($ordinal !== null && $previousListingIds !== []) {
            $listingId = $previousListingIds[$ordinal - 1] ?? null;

            return [
                'action' => self::ACTION_DETAIL,
                'filters' => $previousFilters,
                'detail_listing_id' => $listingId,
                'language' => $language,
                'matched_location_label' => null,
            ];
        }

        $isReset = $this->containsAny($normalized, self::RESET_KEYWORDS);
        $baseFilters = $isReset ? [] : $previousFilters;

        $propertyType = $this->extractPropertyType($normalized);
        $purpose = $this->extractPurpose($normalized);
        $bedroomsMin = $this->extractBedroomsMin($normalized);
        [$minPrice, $maxPrice] = $this->extractPriceRange($normalized);
        $location = $this->extractLocation($normalized);
        $amenityIds = $this->extractAmenityIds($normalized);

        // Relative refinements only make sense against a previous search.
        if (! $isReset && $previousFilters !== []) {
            if ($maxPrice === null && isset($previousFilters['max_price']) && $this->containsAny($normalized, self::CHEAPER_KEYWORDS)) {
                $maxPrice = round(((float) $previousFilters['max_price']) * 0.8);
            }
            if ($maxPrice === null && isset($previousFilters['max_price']) && $this->containsAny($normalized, self::PRICIER_KEYWORDS)) {
                $maxPrice = round(((float) $previousFilters['max_price']) * 1.2);
            }
            if ($bedroomsMin === null && $this->containsAny($normalized, self::MORE_BEDROOMS_KEYWORDS)) {
                $bedroomsMin = ((int) ($previousFilters['bedrooms_min'] ?? 0)) + 1;
            }
        }

        $filters = $baseFilters;
        $set = function (string $key, mixed $value) use (&$filters) {
            if ($value !== null) {
                $filters[$key] = $value;
            }
        };

        $set('property_type', $propertyType);
        $set('purpose', $purpose);
        $set('bedrooms_min', $bedroomsMin);
        $set('min_price', $minPrice);
        $set('max_price', $maxPrice);
        if ($amenityIds !== []) {
            $filters['amenity_ids'] = $amenityIds;
        }
        if ($location !== null) {
            // A new location replaces any previous one rather than stacking —
            // only one of these should ever be set at a time.
            foreach (['district_id', 'municipality_id', 'neighborhood_id'] as $key) {
                unset($filters[$key]);
            }
            $filters[$location['type'].'_id'] = $location['id'];
        }

        $hasMeaningfulFilter = array_key_exists('property_type', $filters)
            || array_key_exists('purpose', $filters)
            || array_key_exists('district_id', $filters)
            || array_key_exists('municipality_id', $filters)
            || array_key_exists('neighborhood_id', $filters)
            || array_key_exists('min_price', $filters)
            || array_key_exists('max_price', $filters)
            || array_key_exists('bedrooms_min', $filters)
            || array_key_exists('amenity_ids', $filters);

        return [
            'action' => $hasMeaningfulFilter ? self::ACTION_SEARCH : self::ACTION_CLARIFY,
            'filters' => $filters,
            'detail_listing_id' => null,
            'language' => $language,
            'matched_location_label' => $location['label'] ?? null,
        ];
    }

    private function detectLanguage(string $message): string
    {
        // Devanagari unicode block first — unambiguous when present.
        if (preg_match('/[\x{0900}-\x{097F}]/u', $message)) {
            return self::LANG_NEPALI;
        }

        // Otherwise check for Nepali typed in Latin script, so a reply can
        // still match the language the user actually typed in rather than
        // defaulting to English just because there's no Devanagari.
        $normalized = mb_strtolower($message);
        foreach (self::ROMANIZED_NEPALI_MARKERS as $marker) {
            if (preg_match('/\b'.preg_quote($marker, '/').'\b/u', $normalized)) {
                return self::LANG_NEPALI_LATIN;
            }
        }

        return self::LANG_ENGLISH;
    }

    private function normalize(string $message): string
    {
        return trim(mb_strtolower($message));
    }

    private function containsAny(string $haystack, array $needles): bool
    {
        foreach ($needles as $needle) {
            if (mb_stripos($haystack, $needle) !== false) {
                return true;
            }
        }

        return false;
    }

    /**
     * PCRE's \b only recognizes ASCII word characters even with the /u
     * modifier, so a word-boundary regex silently never matches Devanagari
     * text (every Devanagari character reads as "non-word", so no boundary
     * ever appears where expected). Use \b for ASCII dictionary words to
     * avoid matching "sale" inside "salem", and plain substring containment
     * for non-ASCII words, which don't have that false-positive risk.
     */
    private function wordMatches(string $normalized, string $word): bool
    {
        if (preg_match('/^[\x20-\x7E]+$/', $word)) {
            return preg_match('/\b'.preg_quote($word, '/').'\b/u', $normalized) === 1;
        }

        return mb_stripos($normalized, $word) !== false;
    }

    private function extractPropertyType(string $normalized): ?string
    {
        foreach (self::PROPERTY_TYPE_SYNONYMS as $word => $type) {
            if ($this->wordMatches($normalized, $word)) {
                return $type;
            }
        }

        return null;
    }

    private function extractPurpose(string $normalized): ?string
    {
        foreach (self::PURPOSE_SYNONYMS as $word => $purpose) {
            if ($this->wordMatches($normalized, $word)) {
                return $purpose;
            }
        }

        return null;
    }

    private function extractBedroomsMin(string $normalized): ?int
    {
        if (preg_match('/(\d+)\s*(?:bhk|bed\s*rooms?|bedrooms?)/u', $normalized, $m)) {
            return (int) $m[1];
        }

        return null;
    }

    /** @return array{0:?float,1:?float} [min_price, max_price] */
    private function extractPriceRange(string $normalized): array
    {
        $num = '(\d[\d,]*(?:\.\d+)?)\s*(k|thousand|lakh|lakhs|crore|crores)?';

        if (preg_match('/between\s+'.$num.'\s*(?:and|to|-)\s*'.$num.'/u', $normalized, $m)) {
            $min = $this->parseAmount($m[1], $m[2] ?? null);
            $max = $this->parseAmount($m[3], $m[4] ?? null);

            return [min($min, $max), max($min, $max)];
        }

        if (preg_match('/(?:under|below|less than|max(?:imum)?|up\s*to)\s*(?:npr|rs\.?)?\s*'.$num.'/u', $normalized, $m)) {
            return [null, $this->parseAmount($m[1], $m[2] ?? null)];
        }

        if (preg_match('/(?:above|over|more than|min(?:imum)?|starting from)\s*(?:npr|rs\.?)?\s*'.$num.'/u', $normalized, $m)) {
            return [$this->parseAmount($m[1], $m[2] ?? null), null];
        }

        if (preg_match('/(?:around|about|approx(?:imately)?)\s*(?:npr|rs\.?)?\s*'.$num.'/u', $normalized, $m)) {
            // No exact bound given — treat the figure as a generous ceiling
            // rather than guessing a symmetric range around it.
            return [null, round($this->parseAmount($m[1], $m[2] ?? null) * 1.2)];
        }

        // A bare number near a budget word, with no comparison word — the
        // common "flat in kathmandu 20000" phrasing.
        if (preg_match('/(?:budget|price|npr|rs\.?)\s*'.$num.'/u', $normalized, $m)) {
            return [null, $this->parseAmount($m[1], $m[2] ?? null)];
        }

        // Last resort: a plain number with no keyword at all — "i am looking
        // 25000 property", "25000 ko ghar chahiyo". Guarded two ways so this
        // doesn't misfire: skip anything immediately followed by an area/room
        // unit (that's a size or bedroom count, not a price), and require a
        // magnitude a real property price could plausibly be — small numbers
        // are far more likely a bedroom/floor/ward count than a price.
        if (
            preg_match('/'.$num.'(?!\s*(?:sqft|sq\.?\s*ft\.?|sq\.?\s*m|aana|ropani|dhur|kattha|bhk|bed\s*rooms?|bedrooms?|%|st|nd|rd|th))/u', $normalized, $m)
            && ($amount = $this->parseAmount($m[1], $m[2] ?? null)) >= 500
        ) {
            return [null, $amount];
        }

        return [null, null];
    }

    private function parseAmount(string $digits, ?string $suffix): float
    {
        $value = (float) str_replace(',', '', $digits);

        return match ($suffix) {
            'k' => $value * 1_000,
            'thousand' => $value * 1_000,
            'lakh', 'lakhs' => $value * 100_000,
            'crore', 'crores' => $value * 10_000_000,
            default => $value,
        };
    }

    /** @return array{type:string,id:int,label:string}|null */
    private function extractLocation(string $normalized): ?array
    {
        foreach (self::LOCATION_ALIASES as $alias => $canonical) {
            if (mb_stripos($normalized, $alias) !== false) {
                $normalized = str_replace($alias, $canonical, $normalized);
            }
        }

        $candidates = $this->locationCandidates();

        foreach ($candidates as $candidate) {
            if (mb_strlen($candidate['name']) < 3) {
                continue; // too short to match without false positives
            }
            if (mb_stripos($normalized, mb_strtolower($candidate['name'])) !== false) {
                return $candidate;
            }
        }

        return null;
    }

    /**
     * All district/municipality/neighborhood names (English + Nepali),
     * longest name first so a more specific name wins over a shorter one
     * that happens to be a substring of it. Cached — this data changes
     * rarely and is identical for every request.
     *
     * @return list<array{type:string,id:int,name:string,label:string}>
     */
    private function locationCandidates(): array
    {
        return Cache::remember('assistant:location-candidates', now()->addHour(), function () {
            $candidates = [];

            foreach (Neighborhood::query()->select('id', 'name', 'name_ne')->get() as $n) {
                $candidates[] = ['type' => 'neighborhood', 'id' => $n->id, 'name' => $n->name, 'label' => $n->name];
                if ($n->name_ne) {
                    $candidates[] = ['type' => 'neighborhood', 'id' => $n->id, 'name' => $n->name_ne, 'label' => $n->name];
                }
            }
            foreach (Municipality::query()->select('id', 'name', 'name_ne')->get() as $m) {
                // Official names carry a civic-type suffix ("Pokhara
                // Metropolitan City", "Bhaktapur Municipality") that almost
                // nobody actually types — match (and display) the bare
                // place name instead.
                $core = self::stripMunicipalitySuffix($m->name);
                $candidates[] = ['type' => 'municipality', 'id' => $m->id, 'name' => $core, 'label' => $core];
                if ($m->name_ne) {
                    $candidates[] = ['type' => 'municipality', 'id' => $m->id, 'name' => $m->name_ne, 'label' => $core];
                }
            }
            foreach (District::query()->select('id', 'name', 'name_ne')->get() as $d) {
                $candidates[] = ['type' => 'district', 'id' => $d->id, 'name' => $d->name, 'label' => $d->name];
                if ($d->name_ne) {
                    $candidates[] = ['type' => 'district', 'id' => $d->id, 'name' => $d->name_ne, 'label' => $d->name];
                }
            }

            usort($candidates, fn ($a, $b) => mb_strlen($b['name']) <=> mb_strlen($a['name']));

            return $candidates;
        });
    }

    /**
     * "Pokhara Metropolitan City" -> "Pokhara", "Bhaktapur Municipality" -> "Bhaktapur".
     * Public/static so AssistantService's reply text can display the same
     * bare name it matched on, not the full civic-type name from the DB.
     */
    public static function stripMunicipalitySuffix(string $name): string
    {
        $suffixes = ['Sub-Metropolitan City', 'Sub Metropolitan City', 'Metropolitan City', 'Rural Municipality', 'Municipality'];

        foreach ($suffixes as $suffix) {
            if (str_ends_with($name, ' '.$suffix)) {
                return trim(substr($name, 0, -strlen($suffix)));
            }
        }

        return $name;
    }

    /** @return list<int> */
    private function extractAmenityIds(string $normalized): array
    {
        $matchedKeys = [];
        foreach (self::AMENITY_SYNONYMS as $word => $key) {
            if (preg_match('/\b'.preg_quote($word, '/').'\b/u', $normalized)) {
                $matchedKeys[] = $key;
            }
        }
        if ($matchedKeys === []) {
            return [];
        }

        return Cache::remember('assistant:amenities', now()->addHour(), fn () => Amenity::query()->select('id', 'key', 'name')->get())
            ->filter(fn (Amenity $a) => in_array($a->key, $matchedKeys, true) || $this->containsAny(mb_strtolower($a->name), $matchedKeys))
            ->pluck('id')
            ->values()
            ->all();
    }

    /** "#2", "number 2", "2nd", "the second one" -> 2, else null. */
    private function extractOrdinalReference(string $normalized): ?int
    {
        if (preg_match('/(?:#|number\s*|no\.?\s*)(\d+)/u', $normalized, $m)) {
            return (int) $m[1];
        }
        if (preg_match('/\b(\d+)(?:st|nd|rd|th)\b/u', $normalized, $m)) {
            return (int) $m[1];
        }

        $words = ['first' => 1, 'second' => 2, 'third' => 3, 'fourth' => 4, 'fifth' => 5];
        foreach ($words as $word => $n) {
            if (preg_match('/\b'.$word.'\b/u', $normalized) && $this->containsAny($normalized, ['more about', 'tell me', 'the '.$word.' one', 'details'])) {
                return $n;
            }
        }

        return null;
    }
}
