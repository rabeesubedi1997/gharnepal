<?php

namespace App\Domain\Seo\Services;

use App\Models\Agency;
use App\Models\Neighborhood;
use App\Models\PropertyListing;
use App\Models\SeoPage;
use Illuminate\Support\Str;

/**
 * Computes the *effective* SEO metadata for every page on the site: an
 * admin-authored override in `seo_pages` (when one exists and is published)
 * layered on top of a sensible auto-generated default built from the page's
 * own data — so no page is ever left with blank/generic meta tags, and an
 * admin only has to touch the pages they actually want to hand-tune.
 */
class SeoService
{
    /**
     * Fixed catalog of the site's static/category pages: page_key => definition.
     * This is also what powers the "static pages" section of the admin SEO list.
     */
    public const STATIC_PAGES = [
        'home' => [
            'label' => 'Homepage',
            'path' => '/',
            'title' => 'Ghar Nepal — Verified Property Marketplace in Nepal',
            'description' => 'Browse verified houses, apartments, rooms, land, and commercial properties across Kathmandu Valley, Pokhara, Chitwan, and Biratnagar — with trust scores and land due-diligence built in.',
        ],
        'buy' => [
            'label' => 'Buy — Properties for Sale',
            'path' => '/buy',
            'title' => 'Properties for Sale in Nepal — Verified Listings | Ghar Nepal',
            'description' => 'Browse verified houses, apartments, and land for sale across Nepal with trust scores, price history, and land due-diligence checks.',
        ],
        'rent' => [
            'label' => 'Rent — Properties for Rent',
            'path' => '/rent',
            'title' => 'Properties for Rent in Nepal — Verified Listings | Ghar Nepal',
            'description' => 'Find verified houses, apartments, and rooms for rent across Nepal with trust scores and a true monthly cost calculator.',
        ],
        'rooms' => [
            'label' => 'Rooms for Rent',
            'path' => '/rooms',
            'title' => 'Rooms for Rent in Nepal | Ghar Nepal',
            'description' => 'Browse verified rooms and shared flats for rent across Nepal, with trust scores and verified owners.',
        ],
        'land' => [
            'label' => 'Land for Sale',
            'path' => '/land',
            'title' => 'Land for Sale in Nepal — With Due-Diligence Checks | Ghar Nepal',
            'description' => 'Browse land plots for sale across Nepal with lalpurja, road-access, and land-classification due-diligence built in.',
        ],
        'commercial' => [
            'label' => 'Commercial Properties',
            'path' => '/commercial',
            'title' => 'Commercial Properties in Nepal | Ghar Nepal',
            'description' => 'Browse verified commercial spaces, shops, and offices for sale or rent across Nepal.',
        ],
        'agents' => [
            'label' => 'Find an Agent',
            'path' => '/agents',
            'title' => 'Verified Real Estate Agents & Agencies in Nepal | Ghar Nepal',
            'description' => 'Browse admin-verified real estate agencies and agents across Nepal before you deal with one.',
        ],
        'neighborhoods' => [
            'label' => 'Explore Neighborhoods',
            'path' => '/neighborhoods',
            'title' => 'Neighborhood Guides for Nepal | Ghar Nepal',
            'description' => 'Explore livability scores, points of interest, and community notes for neighborhoods across Nepal.',
        ],
        'calculators-rental' => [
            'label' => 'Rental Cost Calculator',
            'path' => '/calculators/rental',
            'title' => 'True Monthly Rental Cost Calculator for Nepal | Ghar Nepal',
            'description' => 'Calculate the real monthly cost of renting in Nepal — rent, deposit, utilities, internet, parking, and moving costs combined.',
        ],
        'property-requests' => [
            'label' => 'Property Requests',
            'path' => '/property-requests',
            'title' => 'Property Requests — Tell Owners What You\'re Looking For | Ghar Nepal',
            'description' => 'Post what property you\'re looking to buy or rent in Nepal, or browse requests from other buyers and renters.',
        ],
        'calculators-purchase' => [
            'label' => 'Purchase Cost Calculator',
            'path' => '/calculators/purchase',
            'title' => 'True Property Purchase Cost Calculator for Nepal | Ghar Nepal',
            'description' => 'Calculate the real cost of buying property in Nepal — registration, agent fees, taxes, and other charges beyond the sale price.',
        ],
    ];

    public function effectiveForStaticPage(string $key): ?array
    {
        if (! isset(self::STATIC_PAGES[$key])) {
            return null;
        }

        $def = self::STATIC_PAGES[$key];

        $structuredData = $key === 'home' ? [
            '@context' => 'https://schema.org',
            '@type' => 'WebSite',
            'name' => 'Ghar Nepal',
            'url' => config('app.frontend_url'),
            'potentialAction' => [
                '@type' => 'SearchAction',
                'target' => config('app.frontend_url').'/search?q={search_term_string}',
                'query-input' => 'required name=search_term_string',
            ],
        ] : null;

        return $this->merge($key, [
            'title' => $def['title'],
            'description' => $def['description'],
            'keywords' => null,
            'path' => $def['path'],
            'og_image' => null,
            'structured_data' => $structuredData,
        ]);
    }

    public function effectiveForListing(PropertyListing $listing): array
    {
        $key = "listing:{$listing->slug}";
        $property = $listing->property;
        $address = $property?->address;
        $locationBits = array_filter([
            $address?->municipality?->name,
            $address?->district?->name,
        ]);
        $locationLabel = implode(', ', $locationBits);

        $priceLabel = 'Rs '.number_format((float) $listing->price);
        if ($listing->purpose === 'rent' && $listing->price_period === 'monthly') {
            $priceLabel .= '/month';
        }

        $title = Str::limit("{$listing->title} — {$priceLabel}".($locationLabel ? " in {$locationLabel}" : ''), 65, '');
        $title .= ' | Ghar Nepal';

        $description = $listing->description
            ? Str::limit(trim(preg_replace('/\s+/', ' ', strip_tags($listing->description))), 155)
            : Str::limit(
                trim(sprintf(
                    '%s for %s%s. %s. %s',
                    ucfirst((string) $property?->property_type),
                    $listing->purpose === 'sale' ? 'sale' : 'rent',
                    $locationLabel ? " in {$locationLabel}" : '',
                    $priceLabel,
                    $property?->bedrooms ? "{$property->bedrooms} bed, {$property->bathrooms} bath" : 'Verified listing',
                )),
                155,
            );

        $coverImage = $property?->relationLoaded('media') ? $property->media->firstWhere('type', 'image') : null;
        $ogImage = $coverImage?->url();

        $structuredData = [
            '@context' => 'https://schema.org',
            '@type' => 'RealEstateListing',
            'name' => $listing->title,
            'description' => $description,
            'url' => config('app.frontend_url')."/listings/{$listing->slug}",
            'datePosted' => $listing->published_at?->toIso8601String(),
            'offers' => [
                '@type' => 'Offer',
                'price' => (float) $listing->price,
                'priceCurrency' => $listing->currency ?? 'NPR',
                'availability' => $listing->isPubliclyVisible() ? 'https://schema.org/InStock' : 'https://schema.org/OutOfStock',
            ],
        ];

        if ($property?->bedrooms) {
            $structuredData['numberOfRooms'] = $property->bedrooms;
        }
        if ($listing->relationLoaded('ratings') || $listing->ratings_count) {
            $count = (int) ($listing->ratings_count ?? 0);
            if ($count > 0) {
                $structuredData['aggregateRating'] = [
                    '@type' => 'AggregateRating',
                    'ratingValue' => round((float) ($listing->ratings_avg_score ?? 0), 1),
                    'reviewCount' => $count,
                ];
            }
        }

        return $this->merge($key, [
            'title' => $title,
            'description' => $description,
            'keywords' => null,
            'path' => "/listings/{$listing->slug}",
            'og_image' => $ogImage,
            'structured_data' => $structuredData,
        ], label: "Listing: {$listing->title}", pageType: 'listing');
    }

    public function effectiveForNeighborhood(Neighborhood $neighborhood): array
    {
        $key = "neighborhood:{$neighborhood->id}";
        $score = $neighborhood->relationLoaded('score') ? $neighborhood->score : null;

        $title = "{$neighborhood->name} Neighborhood Guide".($score ? " — Livability {$score->overall_score}/10" : '').' | Ghar Nepal';
        $description = "Explore {$neighborhood->name}'s livability score, points of interest, and community notes on Ghar Nepal.";

        $structuredData = [
            '@context' => 'https://schema.org',
            '@type' => 'Place',
            'name' => $neighborhood->name,
            'url' => config('app.frontend_url')."/neighborhoods/{$neighborhood->id}",
        ];

        return $this->merge($key, [
            'title' => $title,
            'description' => $description,
            'keywords' => null,
            'path' => "/neighborhoods/{$neighborhood->id}",
            'og_image' => null,
            'structured_data' => $structuredData,
        ], label: "Neighborhood: {$neighborhood->name}", pageType: 'neighborhood');
    }

    public function effectiveForAgency(Agency $agency): array
    {
        $key = "agency:{$agency->slug}";

        $title = "{$agency->name} — Verified Real Estate Agency in Nepal | Ghar Nepal";
        $description = $agency->description
            ? Str::limit(trim(preg_replace('/\s+/', ' ', strip_tags($agency->description))), 155)
            : "{$agency->name} is a real estate agency listed on Ghar Nepal.".($agency->isVerified() ? ' Verified by our admin team.' : '');

        $logoUrl = $agency->logo_path ? \Illuminate\Support\Facades\Storage::disk('public')->url($agency->logo_path) : null;

        $structuredData = [
            '@context' => 'https://schema.org',
            '@type' => 'RealEstateAgent',
            'name' => $agency->name,
            'description' => $description,
            'url' => config('app.frontend_url')."/agents/{$agency->slug}",
        ];
        if ($logoUrl) {
            $structuredData['image'] = $logoUrl;
        }

        return $this->merge($key, [
            'title' => $title,
            'description' => $description,
            'keywords' => null,
            'path' => "/agents/{$agency->slug}",
            'og_image' => $logoUrl,
            'structured_data' => $structuredData,
        ], label: "Agency: {$agency->name}", pageType: 'agency');
    }

    /**
     * @param  array{title:string,description:?string,keywords:?string,path:string,og_image:?string,structured_data:?array}  $defaults
     */
    private function merge(string $pageKey, array $defaults, ?string $label = null, string $pageType = 'static'): array
    {
        $override = SeoPage::query()->where('page_key', $pageKey)->first();
        $useOverride = $override && $override->isLive();

        $path = ($useOverride ? $override->canonical_path : null) ?: $defaults['path'];

        return [
            'page_key' => $pageKey,
            'page_type' => $pageType,
            'label' => $label ?? (self::STATIC_PAGES[$pageKey]['label'] ?? $pageKey),
            'title' => ($useOverride ? $override->meta_title : null) ?: $defaults['title'],
            'description' => ($useOverride ? $override->meta_description : null) ?: $defaults['description'],
            'keywords' => ($useOverride ? $override->meta_keywords : null) ?: $defaults['keywords'],
            'canonical_url' => config('app.frontend_url').$path,
            'og_image' => ($useOverride ? $override->og_image_url : null) ?: $defaults['og_image'],
            'robots' => [
                'index' => $useOverride ? $override->robots_index : true,
                'follow' => $useOverride ? $override->robots_follow : true,
            ],
            'structured_data' => $defaults['structured_data'],
            'has_override' => (bool) $override,
            'override_status' => $override?->status,
        ];
    }
}
