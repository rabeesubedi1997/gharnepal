<?php

namespace Database\Seeders;

use App\Domain\Calculators\Services\AreaUnitConverter;
use App\Domain\Trust\Services\TrustScoreCalculator;
use App\Models\Agency;
use App\Models\Amenity;
use App\Models\Media;
use App\Models\Municipality;
use App\Models\Neighborhood;
use App\Models\Property;
use App\Models\PropertyListing;
use App\Models\Role;
use App\Models\User;
use App\Models\Ward;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

/**
 * Populates the marketplace with realistic demo content so the UI is never
 * shown near-empty to a first-time visitor: several individual owners plus
 * two verified real-estate agencies (and one deliberately unverified one, to
 * prove it's excluded from the public directory), ~28 published listings
 * spread across every property type/purpose/MVP city, each with real stock
 * photos, realistic NPR pricing, amenities, and — for land — a filled-in
 * due-diligence profile. Trust scores are computed for real via
 * TrustScoreCalculator, never hardcoded.
 *
 * Safe to re-run: agencies/users are keyed by email/slug via
 * updateOrCreate; listings are keyed by slug the same way.
 */
class DemoDataSeeder extends Seeder
{
    private TrustScoreCalculator $trustScoreCalculator;

    /** @var array<string, array{lat: float, lng: float}> */
    private const CITY_CENTERS = [
        'M-KTM' => ['lat' => 27.7172, 'lng' => 85.3240],
        'M-LTP' => ['lat' => 27.6588, 'lng' => 85.3247],
        'M-BKT' => ['lat' => 27.6710, 'lng' => 85.4298],
        'M-PKR' => ['lat' => 28.2096, 'lng' => 83.9856],
        'M-BRT' => ['lat' => 27.6244, 'lng' => 84.4280],
        'M-BRG' => ['lat' => 26.4525, 'lng' => 87.2718],
    ];

    public function run(): void
    {
        $this->trustScoreCalculator = app(TrustScoreCalculator::class);

        $owners = $this->seedIndividualOwners();
        $agentPool = $this->seedAgencies();
        $posters = $owners->concat($agentPool);

        $i = 0;
        foreach ($this->listingSpecs() as $spec) {
            $poster = $posters[$i % $posters->count()];
            $this->createListing($spec, $poster);
            $i++;
        }
    }

    /** @return \Illuminate\Support\Collection<int, User> */
    private function seedIndividualOwners()
    {
        $names = [
            ['Bikash Shrestha', 'bikash.shrestha'],
            ['Anita Gurung', 'anita.gurung'],
            ['Suresh Tamang', 'suresh.tamang'],
            ['Priya Maharjan', 'priya.maharjan'],
            ['Nabin Rai', 'nabin.rai'],
            ['Sushmita Thapa', 'sushmita.thapa'],
            ['Dipendra Karki', 'dipendra.karki'],
            ['Kabita Poudel', 'kabita.poudel'],
        ];

        return collect($names)->map(function ($pair, $i) {
            [$name, $slug] = $pair;

            $user = User::query()->updateOrCreate(
                ['email' => "{$slug}@demo.gharnepal.test"],
                [
                    'name' => $name,
                    'password' => 'password',
                    'phone' => '98' . str_pad((string) (10000000 + $i), 8, '0', STR_PAD_LEFT),
                    'phone_verified_at' => now(),
                    'email_verified_at' => now(),
                ],
            );
            $user->roles()->syncWithoutDetaching(Role::where('key', Role::OWNER)->pluck('id'));

            return $user;
        });
    }

    /** @return \Illuminate\Support\Collection<int, User> flattened pool of agent users, ready to post listings */
    private function seedAgencies()
    {
        $agentRoleId = Role::where('key', Role::AGENT)->value('id');

        $definitions = [
            [
                'name' => 'Himalayan Homes Realty',
                'slug' => 'himalayan-homes-realty',
                'description' => 'A Kathmandu Valley-focused agency specializing in residential sales and rentals, with over a decade of local market experience.',
                'verified' => true,
                'agents' => [
                    ['Rajan Bhattarai', 'rajan.bhattarai'],
                    ['Manisha Adhikari', 'manisha.adhikari'],
                    ['Prakash Basnet', 'prakash.basnet'],
                ],
            ],
            [
                'name' => 'Kathmandu Property Partners',
                'slug' => 'kathmandu-property-partners',
                'description' => 'Full-service brokerage covering land, apartments, and commercial space across the Kathmandu Valley and Pokhara.',
                'verified' => true,
                'agents' => [
                    ['Sunita Lama', 'sunita.lama'],
                    ['Bishnu Acharya', 'bishnu.acharya'],
                ],
            ],
            [
                'name' => 'Everest Realty Group',
                'slug' => 'everest-realty-group',
                'description' => 'Newly registered agency, still under admin review.',
                'verified' => false,
                'agents' => [
                    ['Ramesh Khadka', 'ramesh.khadka'],
                ],
            ],
        ];

        $agentPool = collect();
        $phoneSeq = 0;

        foreach ($definitions as $def) {
            $agency = Agency::query()->updateOrCreate(
                ['slug' => $def['slug']],
                [
                    'name' => $def['name'],
                    'description' => $def['description'],
                    'status' => $def['verified'] ? 'active' : 'pending',
                    'verified_at' => $def['verified'] ? now() : null,
                ],
            );

            foreach ($def['agents'] as $i => [$name, $slug]) {
                $agent = User::query()->updateOrCreate(
                    ['email' => "{$slug}@demo.gharnepal.test"],
                    [
                        'name' => $name,
                        'password' => 'password',
                        'phone' => '97' . str_pad((string) (20000000 + $phoneSeq++), 8, '0', STR_PAD_LEFT),
                        'phone_verified_at' => now(),
                        'email_verified_at' => now(),
                    ],
                );
                $agent->roles()->syncWithoutDetaching([$agentRoleId]);
                $agency->members()->syncWithoutDetaching([$agent->id => ['role_in_agency' => $i === 0 ? 'owner_admin' : 'agent']]);

                // Only pull from verified agencies' agents to post demo listings —
                // the unverified agency exists purely to prove it's excluded from
                // the public directory, not to generate visible content.
                if ($def['verified']) {
                    $agentPool->push($agent);
                }
            }
        }

        return $agentPool;
    }

    private function createListing(array $spec, User $poster): void
    {
        // Deterministic slug (no random suffix) so a re-run can detect an
        // already-seeded listing and skip it instead of creating a duplicate
        // property. This is the actual idempotency guard for this seeder.
        $slug = Str::slug($spec['title']);
        if (PropertyListing::where('slug', $slug)->exists()) {
            return;
        }

        $municipality = Municipality::where('code', $spec['city'])->firstOrFail();
        $ward = Ward::where('municipality_id', $municipality->id)->where('ward_number', 1)->firstOrFail();
        $center = self::CITY_CENTERS[$spec['city']];
        $neighborhood = isset($spec['neighborhood'])
            ? Neighborhood::where('ward_id', $ward->id)->where('name', $spec['neighborhood'])->first()
            : null;

        $sqm = AreaUnitConverter::toSqm($spec['area_value'], $spec['area_unit']);

        $property = Property::create([
            'owner_user_id' => $poster->id,
            'created_by' => $poster->id,
            'property_type' => $spec['type'],
            'total_area_sqm' => $sqm,
            'total_area_unit_entered' => $spec['area_unit'],
            'total_area_value_entered' => $spec['area_value'],
            'bedrooms' => $spec['bedrooms'] ?? null,
            'bathrooms' => $spec['bathrooms'] ?? null,
            'floors' => $spec['floors'] ?? null,
            'parking_spaces' => $spec['parking_spaces'] ?? 0,
            'is_furnished' => $spec['is_furnished'] ?? null,
        ]);

        $property->address()->create([
            'province_id' => $municipality->district->province_id,
            'district_id' => $municipality->district_id,
            'municipality_id' => $municipality->id,
            'ward_id' => $ward->id,
            'neighborhood_id' => $neighborhood?->id,
            'street_address' => $spec['street_address'] ?? null,
            'lat' => $center['lat'] + (mt_rand(-150, 150) / 10000),
            'lng' => $center['lng'] + (mt_rand(-150, 150) / 10000),
        ]);
        $property->managers()->syncWithoutDetaching([$poster->id => ['relation' => $poster->hasRole(Role::AGENT) ? 'listing_agent' : 'owner']]);

        $this->attachMedia($property, $spec['media'], $poster);

        if ($spec['type'] === 'land') {
            $property->landProfile()->create($spec['land_profile'] ?? [
                'lalpurja_available' => 'yes',
                'road_access' => true,
                'road_width_meters' => 6,
                'road_type' => 'blacktop',
                'water_access' => 'municipal',
                'electricity_access' => true,
                'drainage_access' => 'yes',
                'land_classification' => 'residential',
                'flood_risk' => 'none',
                'landslide_risk' => 'none',
                'document_verification_status' => 'verified',
            ]);
        }

        $publishedAt = now()->subDays($spec['published_days_ago'] ?? mt_rand(2, 90));

        $listing = $property->listings()->create([
            'purpose' => $spec['purpose'],
            'price' => $spec['price'],
            'price_period' => $spec['purpose'] === 'rent' ? 'monthly' : 'total',
            'currency' => 'NPR',
            'negotiable' => $spec['negotiable'] ?? false,
            'status' => PropertyListing::STATUS_PUBLISHED,
            'title' => $spec['title'],
            'slug' => $slug,
            'description' => $spec['description'],
            'published_at' => $publishedAt,
            'views_count' => mt_rand(3, 180),
            'created_by' => $poster->id,
            'featured_until' => ($spec['featured'] ?? false) ? now()->addDays(14) : null,
        ]);

        $listing->priceHistory()->create(['price' => $spec['price'], 'changed_at' => $publishedAt]);

        if (! empty($spec['amenities'])) {
            $amenityIds = Amenity::whereIn('key', $spec['amenities'])->pluck('id');
            $listing->amenities()->syncWithoutDetaching($amenityIds);
        }

        $this->trustScoreCalculator->recompute($listing);
    }

    private function attachMedia(Property $property, array $filenames, User $uploader): void
    {
        foreach ($filenames as $i => $filename) {
            $diskPath = "demo/{$filename}.jpg";
            $fullPath = storage_path("app/public/{$diskPath}");
            $dimensions = @getimagesize($fullPath);

            Media::create([
                'mediable_type' => Property::class,
                'mediable_id' => $property->id,
                'type' => 'image',
                'disk_path' => $diskPath,
                'mime_type' => 'image/jpeg',
                'size_bytes' => @filesize($fullPath) ?: 150000,
                'width' => $dimensions[0] ?? 1200,
                'height' => $dimensions[1] ?? 800,
                'sort_order' => $i,
                'uploaded_by' => $uploader->id,
            ]);
        }
    }

    /** @return array<int, array<string, mixed>> */
    private function listingSpecs(): array
    {
        $house = ['house-exterior-1', 'living-room-1', 'kitchen-1', 'bedroom-1'];
        $house2 = ['house-exterior-2', 'living-room-2', 'kitchen-2', 'bedroom-2'];
        $house3 = ['house-exterior-3', 'living-room-1', 'bedroom-1'];
        $house4 = ['house-exterior-4', 'living-room-2', 'kitchen-1'];
        $apt = ['apartment-building-1', 'living-room-1', 'kitchen-2', 'bedroom-2'];
        $apt2 = ['apartment-building-2', 'living-room-2', 'kitchen-1', 'bedroom-1'];
        $room = ['bedroom-1', 'studio-room-1'];
        $room2 = ['bedroom-2', 'studio-room-1'];
        $land = ['land-plot-1'];
        $land2 = ['land-plot-2'];
        $commercial = ['office-space-1', 'office-space-2'];
        $shop = ['shop-space-1', 'office-space-2'];

        return [
            // --- Kathmandu ---
            ['city' => 'M-KTM', 'type' => 'apartment', 'purpose' => 'rent', 'price' => 32000, 'bedrooms' => 3, 'bathrooms' => 2, 'floors' => 1, 'area_value' => 1400, 'area_unit' => 'sqft', 'parking_spaces' => 1, 'is_furnished' => 'semi', 'neighborhood' => 'Baneshwor', 'title' => 'Modern 3BHK Apartment in Baneshwor', 'description' => 'Bright semi-furnished apartment on a quiet lane, close to Ring Road and public transport. Includes covered parking and 24-hour water supply.', 'amenities' => ['parking', 'lift', 'water_tank', 'internet_wifi'], 'media' => $apt, 'featured' => true],
            ['city' => 'M-KTM', 'type' => 'apartment', 'purpose' => 'sale', 'price' => 18500000, 'bedrooms' => 4, 'bathrooms' => 3, 'floors' => 1, 'area_value' => 1800, 'area_unit' => 'sqft', 'parking_spaces' => 2, 'is_furnished' => 'full', 'neighborhood' => 'Maharajgunj', 'title' => 'Fully Furnished 4BHK Apartment in Maharajgunj', 'description' => 'Premium apartment in a gated complex near embassies and international schools. Elevator access, backup generator, and CCTV throughout.', 'amenities' => ['lift', 'generator', 'cctv', 'security_guard', 'parking'], 'media' => $apt2],
            ['city' => 'M-KTM', 'type' => 'house', 'purpose' => 'sale', 'price' => 32000000, 'bedrooms' => 5, 'bathrooms' => 4, 'floors' => 3, 'area_value' => 6, 'area_unit' => 'aana', 'parking_spaces' => 2, 'is_furnished' => 'unfurnished', 'neighborhood' => 'Chabahil', 'title' => 'Spacious 3-Storey House for Sale in Chabahil', 'description' => 'Earthquake-resistant RCC construction completed in 2019. Wide road access, private garden, and separate servant quarter.', 'amenities' => ['earthquake_resistant', 'garden', 'servant_quarter', 'water_tank', 'parking'], 'media' => $house, 'negotiable' => true],
            ['city' => 'M-KTM', 'type' => 'house', 'purpose' => 'rent', 'price' => 65000, 'bedrooms' => 4, 'bathrooms' => 3, 'floors' => 2, 'area_value' => 5, 'area_unit' => 'aana', 'parking_spaces' => 2, 'is_furnished' => 'semi', 'neighborhood' => 'Koteshwor', 'title' => 'Independent House for Rent in Koteshwor', 'description' => 'Full house available for a family — private compound, ample parking, and quick access to the airport and Ring Road.', 'amenities' => ['parking', 'water_tank', 'balcony'], 'media' => $house2],
            ['city' => 'M-KTM', 'type' => 'room', 'purpose' => 'rent', 'price' => 9500, 'bedrooms' => 1, 'bathrooms' => 1, 'is_furnished' => 'semi', 'neighborhood' => 'Thamel', 'area_value' => 150, 'area_unit' => 'sqft', 'title' => 'Cozy Single Room near Thamel', 'description' => 'Affordable single room ideal for students or a young professional, walking distance to Thamel and New Road markets.', 'amenities' => ['internet_wifi', 'water_tank'], 'media' => $room],
            ['city' => 'M-KTM', 'type' => 'room', 'purpose' => 'rent', 'price' => 12000, 'bedrooms' => 1, 'bathrooms' => 1, 'is_furnished' => 'full', 'neighborhood' => 'Boudha', 'area_value' => 180, 'area_unit' => 'sqft', 'title' => 'Furnished Room with Attached Bathroom in Boudha', 'description' => 'Quiet residential room near the Boudhanath Stupa, popular with monastery staff and long-term expat tenants.', 'amenities' => ['internet_wifi', 'balcony'], 'media' => $room2],
            ['city' => 'M-KTM', 'type' => 'land', 'purpose' => 'sale', 'price' => 8500000, 'area_value' => 4, 'area_unit' => 'aana', 'neighborhood' => 'Gongabu', 'title' => 'Residential Land Plot in Gongabu', 'description' => 'Flat, road-facing plot close to the Gongabu bus park — suitable for immediate construction.', 'media' => $land, 'land_profile' => ['kitta_number' => '142/6', 'lalpurja_available' => 'yes', 'road_access' => true, 'road_width_meters' => 8, 'road_type' => 'blacktop', 'water_access' => 'municipal', 'electricity_access' => true, 'drainage_access' => 'yes', 'land_classification' => 'residential', 'flood_risk' => 'none', 'landslide_risk' => 'none', 'document_verification_status' => 'verified']],
            ['city' => 'M-KTM', 'type' => 'commercial', 'purpose' => 'rent', 'price' => 85000, 'floors' => 1, 'area_value' => 1200, 'area_unit' => 'sqft', 'parking_spaces' => 3, 'title' => 'Ground Floor Commercial Space in New Road', 'description' => 'High-footfall retail space on a main commercial street, previously operated as a garments showroom.', 'amenities' => ['cctv', 'security_guard', 'parking'], 'media' => $shop],
            ['city' => 'M-KTM', 'type' => 'commercial', 'purpose' => 'sale', 'price' => 45000000, 'floors' => 2, 'area_value' => 2200, 'area_unit' => 'sqft', 'parking_spaces' => 4, 'title' => 'Commercial Building for Sale in Kalanki', 'description' => 'Two-storey commercial building with rental income potential from three existing tenant shops.', 'amenities' => ['cctv', 'parking', 'generator'], 'media' => $commercial],

            // --- Lalitpur ---
            ['city' => 'M-LTP', 'type' => 'apartment', 'purpose' => 'rent', 'price' => 38000, 'bedrooms' => 3, 'bathrooms' => 2, 'floors' => 1, 'area_value' => 1500, 'area_unit' => 'sqft', 'parking_spaces' => 1, 'is_furnished' => 'full', 'neighborhood' => 'Jawalakhel', 'title' => 'Furnished Apartment for Rent in Jawalakhel', 'description' => 'Walking distance to Patan Hospital and Jawalakhel Chowk, ideal for a diplomatic or professional family.', 'amenities' => ['lift', 'parking', 'internet_wifi', 'cctv'], 'media' => $apt, 'featured' => true],
            ['city' => 'M-LTP', 'type' => 'house', 'purpose' => 'sale', 'price' => 42000000, 'bedrooms' => 5, 'bathrooms' => 4, 'floors' => 3, 'area_value' => 7, 'area_unit' => 'aana', 'parking_spaces' => 3, 'is_furnished' => 'unfurnished', 'neighborhood' => 'Sanepa', 'title' => 'Luxury House for Sale in Sanepa', 'description' => 'High-end finishing throughout, rooftop terrace with valley views, and a private lawn — one of Sanepa\'s quieter lanes.', 'amenities' => ['terrace', 'garden', 'earthquake_resistant', 'parking'], 'media' => $house3],
            ['city' => 'M-LTP', 'type' => 'room', 'purpose' => 'rent', 'price' => 11000, 'bedrooms' => 1, 'bathrooms' => 1, 'is_furnished' => 'semi', 'neighborhood' => 'Kupondole', 'area_value' => 160, 'area_unit' => 'sqft', 'title' => 'Single Room for Rent in Kupondole', 'description' => 'Close to Kupondole\'s cafes and offices — good option for a working professional commuting into central Kathmandu.', 'amenities' => ['internet_wifi'], 'media' => $room],
            ['city' => 'M-LTP', 'type' => 'land', 'purpose' => 'sale', 'price' => 12000000, 'area_value' => 5, 'area_unit' => 'aana', 'neighborhood' => 'Ekantakuna', 'title' => 'Residential Plot in Ekantakuna', 'description' => 'Corner plot with two-side road access, close to the Ring Road interchange.', 'media' => $land2, 'land_profile' => ['kitta_number' => '88/2', 'lalpurja_available' => 'yes', 'road_access' => true, 'road_width_meters' => 6, 'road_type' => 'gravel', 'water_access' => 'municipal', 'electricity_access' => true, 'drainage_access' => 'yes', 'land_classification' => 'residential', 'flood_risk' => 'none', 'landslide_risk' => 'none', 'document_verification_status' => 'partial']],
            ['city' => 'M-LTP', 'type' => 'commercial', 'purpose' => 'rent', 'price' => 55000, 'floors' => 1, 'area_value' => 900, 'area_unit' => 'sqft', 'parking_spaces' => 2, 'neighborhood' => 'Pulchowk', 'title' => 'Office Space for Rent in Pulchowk', 'description' => 'Modern office floor near Pulchowk Engineering Campus, suitable for a startup or consultancy.', 'amenities' => ['internet_wifi', 'lift', 'parking'], 'media' => $commercial],

            // --- Bhaktapur ---
            ['city' => 'M-BKT', 'type' => 'house', 'purpose' => 'sale', 'price' => 21000000, 'bedrooms' => 4, 'bathrooms' => 3, 'floors' => 2, 'area_value' => 4, 'area_unit' => 'aana', 'parking_spaces' => 1, 'is_furnished' => 'unfurnished', 'neighborhood' => 'Suryabinayak', 'title' => 'Traditional-Style House for Sale in Suryabinayak', 'description' => 'Brick-and-timber facade in keeping with Bhaktapur\'s heritage style, modern interior finishing.', 'amenities' => ['parking', 'water_tank'], 'media' => $house4],
            ['city' => 'M-BKT', 'type' => 'room', 'purpose' => 'rent', 'price' => 7500, 'bedrooms' => 1, 'bathrooms' => 1, 'is_furnished' => 'semi', 'neighborhood' => 'Kamalbinayak', 'area_value' => 130, 'area_unit' => 'sqft', 'title' => 'Budget Room for Rent in Kamalbinayak', 'description' => 'Simple, affordable room near Kamalbinayak temple — quiet neighborhood, good for students.', 'amenities' => ['water_tank'], 'media' => $room2],
            ['city' => 'M-BKT', 'type' => 'land', 'purpose' => 'sale', 'price' => 6200000, 'area_value' => 3, 'area_unit' => 'aana', 'title' => 'Land for Sale near Bhaktapur Durbar Square', 'description' => 'Small residential plot within walking distance of the Durbar Square heritage area.', 'media' => $land, 'land_profile' => ['kitta_number' => '55/9', 'lalpurja_available' => 'yes', 'road_access' => true, 'road_width_meters' => 4, 'road_type' => 'gravel', 'water_access' => 'well', 'electricity_access' => true, 'drainage_access' => 'yes', 'land_classification' => 'residential', 'flood_risk' => 'none', 'landslide_risk' => 'none', 'document_verification_status' => 'unverified']],

            // --- Pokhara ---
            ['city' => 'M-PKR', 'type' => 'house', 'purpose' => 'sale', 'price' => 28000000, 'bedrooms' => 4, 'bathrooms' => 3, 'floors' => 2, 'area_value' => 5, 'area_unit' => 'aana', 'parking_spaces' => 2, 'is_furnished' => 'semi', 'neighborhood' => 'Lakeside', 'title' => 'Lake-View House for Sale in Lakeside', 'description' => 'A short walk from Phewa Lake, popular tourist strip nearby — strong potential for guesthouse conversion.', 'amenities' => ['terrace', 'balcony', 'parking'], 'media' => $house, 'featured' => true],
            ['city' => 'M-PKR', 'type' => 'apartment', 'purpose' => 'rent', 'price' => 25000, 'bedrooms' => 2, 'bathrooms' => 2, 'floors' => 1, 'area_value' => 1100, 'area_unit' => 'sqft', 'parking_spaces' => 1, 'is_furnished' => 'full', 'neighborhood' => 'Chipledhunga', 'title' => 'Furnished 2BHK Apartment in Chipledhunga', 'description' => 'Central Pokhara location close to Mahendrapul market, ideal for a small family or working couple.', 'amenities' => ['lift', 'parking', 'internet_wifi'], 'media' => $apt2],
            ['city' => 'M-PKR', 'type' => 'land', 'purpose' => 'sale', 'price' => 9800000, 'area_value' => 4, 'area_unit' => 'aana', 'neighborhood' => 'Bagar', 'title' => 'Residential Plot for Sale in Bagar', 'description' => 'Level plot in a developing residential pocket, a short drive from the airport.', 'media' => $land2, 'land_profile' => ['kitta_number' => '212/1', 'lalpurja_available' => 'yes', 'road_access' => true, 'road_width_meters' => 5, 'road_type' => 'gravel', 'water_access' => 'municipal', 'electricity_access' => true, 'drainage_access' => 'yes', 'land_classification' => 'residential', 'flood_risk' => 'low', 'landslide_risk' => 'none', 'document_verification_status' => 'verified']],
            ['city' => 'M-PKR', 'type' => 'room', 'purpose' => 'rent', 'price' => 8500, 'bedrooms' => 1, 'bathrooms' => 1, 'is_furnished' => 'semi', 'neighborhood' => 'Mahendrapul', 'area_value' => 140, 'area_unit' => 'sqft', 'title' => 'Single Room for Rent in Mahendrapul', 'description' => 'Close to Pokhara\'s main bazaar, convenient for students attending nearby colleges.', 'amenities' => ['water_tank'], 'media' => $room],
            ['city' => 'M-PKR', 'type' => 'commercial', 'purpose' => 'rent', 'price' => 40000, 'floors' => 1, 'area_value' => 800, 'area_unit' => 'sqft', 'parking_spaces' => 1, 'title' => 'Shop Space for Rent in Lakeside', 'description' => 'Tourist-facing shop space on Lakeside\'s main road, previously a trekking-gear outlet.', 'amenities' => ['cctv'], 'media' => $shop],

            // --- Bharatpur / Chitwan ---
            ['city' => 'M-BRT', 'type' => 'house', 'purpose' => 'sale', 'price' => 15500000, 'bedrooms' => 4, 'bathrooms' => 3, 'floors' => 2, 'area_value' => 6, 'area_unit' => 'aana', 'parking_spaces' => 2, 'is_furnished' => 'unfurnished', 'neighborhood' => 'Narayangarh', 'title' => 'Family House for Sale in Narayangarh', 'description' => 'Well-maintained house on a wide street, close to Bharatpur\'s main hospital and schools.', 'amenities' => ['parking', 'garden'], 'media' => $house2],
            ['city' => 'M-BRT', 'type' => 'land', 'purpose' => 'sale', 'price' => 5200000, 'area_value' => 8, 'area_unit' => 'kattha', 'neighborhood' => 'Bharatpur Chowk', 'title' => 'Terai Plot for Sale near Bharatpur Chowk', 'description' => 'Flat agricultural-adjacent land with municipal road frontage, suitable for residential development.', 'media' => $land, 'land_profile' => ['kitta_number' => '301/4', 'lalpurja_available' => 'yes', 'road_access' => true, 'road_width_meters' => 7, 'road_type' => 'blacktop', 'water_access' => 'well', 'electricity_access' => true, 'drainage_access' => 'yes', 'land_classification' => 'residential', 'flood_risk' => 'low', 'landslide_risk' => 'none', 'document_verification_status' => 'verified']],

            // --- Biratnagar ---
            ['city' => 'M-BRG', 'type' => 'apartment', 'purpose' => 'rent', 'price' => 18000, 'bedrooms' => 2, 'bathrooms' => 2, 'floors' => 1, 'area_value' => 950, 'area_unit' => 'sqft', 'parking_spaces' => 1, 'is_furnished' => 'semi', 'neighborhood' => 'Traffic Chowk', 'title' => 'Apartment for Rent near Traffic Chowk', 'description' => 'Centrally located near Biratnagar\'s main commercial hub, good access to markets and transport.', 'amenities' => ['parking', 'water_tank'], 'media' => $apt],
            ['city' => 'M-BRG', 'type' => 'house', 'purpose' => 'sale', 'price' => 13500000, 'bedrooms' => 4, 'bathrooms' => 3, 'floors' => 2, 'area_value' => 5, 'area_unit' => 'kattha', 'parking_spaces' => 2, 'is_furnished' => 'unfurnished', 'neighborhood' => 'Rani', 'title' => 'House for Sale in Rani', 'description' => 'Spacious Terai-style house with a large courtyard, close to Rani\'s local market.', 'amenities' => ['parking', 'water_tank', 'garden'], 'media' => $house3],
        ];
    }
}
