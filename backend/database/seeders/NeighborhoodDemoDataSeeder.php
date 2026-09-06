<?php

namespace Database\Seeders;

use App\Models\Neighborhood;
use App\Models\NeighborhoodScore;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * Gives a handful of well-known MVP-city neighborhoods a real admin-curated
 * score + a few POIs, so the neighborhood directory/profile screens have
 * genuine demo content instead of an all-empty list. Everything else stays
 * uncurated (is_curated = false) until real admin content-ops happens.
 */
class NeighborhoodDemoDataSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::query()->where('email', 'superadmin@gharnepal.local')->first();

        $curated = [
            'Thamel' => [
                'is_curated' => true,
                'scores' => [
                    'transport_access' => [9, 'Dense taxi/e-rickshaw availability, walkable core.'],
                    'schools' => [4, 'Few schools nearby; mostly a commercial/tourist district.'],
                    'hospitals' => [7, 'Close to Nardevi/Bir Hospital corridor.'],
                    'markets' => [10, 'Extremely dense retail, grocery, and dining.'],
                    'internet_availability' => [9, 'Strong fiber coverage due to hospitality demand.'],
                    'road_quality' => [6, 'Narrow lanes, congested but paved.'],
                    'noise' => [3, 'High nightlife and traffic noise.'],
                    'safety' => [6, 'Generally safe but busy with tourist-targeted petty theft reports.'],
                    'flood_risk' => [7, 'Minimal flooding history.'],
                    'rental_demand' => [9, 'Very high short-let and commercial demand.'],
                    'development_activity' => [7, 'Ongoing renovation of guesthouses and cafes.'],
                ],
                'pois' => [
                    ['poi_type' => 'market', 'name' => 'Thamel Chowk Market', 'lat' => 27.7154, 'lng' => 85.3123],
                    ['poi_type' => 'transport_stop', 'name' => 'Thamel Taxi Stand', 'lat' => 27.7159, 'lng' => 85.3106],
                    ['poi_type' => 'hospital', 'name' => 'Nardevi Ayurveda Hospital', 'lat' => 27.7089, 'lng' => 85.3086],
                ],
            ],
            'Boudha' => [
                'is_curated' => true,
                'scores' => [
                    'transport_access' => [7, 'Regular bus routes to Ring Road and city center.'],
                    'schools' => [7, 'Several private schools within 2km.'],
                    'hospitals' => [6, 'Norvic and small clinics nearby.'],
                    'markets' => [7, 'Local markets around the stupa plus everyday grocers.'],
                    'internet_availability' => [7, 'Standard fiber coverage.'],
                    'road_quality' => [6, 'Mixed — main roads paved, side lanes uneven.'],
                    'noise' => [6, 'Quieter than city core outside festival periods.'],
                    'safety' => [8, 'Residential, well-regarded for safety.'],
                    'flood_risk' => [7, 'Low-lying in a few pockets near the stream.'],
                    'rental_demand' => [8, 'Popular with expats and monastery-affiliated residents.'],
                    'development_activity' => [6, 'Steady mid-rise apartment construction.'],
                ],
                'pois' => [
                    ['poi_type' => 'school', 'name' => 'Boudha Secondary School', 'lat' => 27.7215, 'lng' => 85.3620],
                    ['poi_type' => 'market', 'name' => 'Boudha Local Market', 'lat' => 27.7212, 'lng' => 85.3606],
                ],
            ],
            'Jawalakhel' => [
                'is_curated' => true,
                'scores' => [
                    'transport_access' => [8, 'Central Lalitpur hub with frequent bus/taxi access.'],
                    'schools' => [8, 'Several reputed schools nearby.'],
                    'hospitals' => [9, 'Patan Hospital is within the neighborhood.'],
                    'markets' => [8, 'Good mix of supermarkets and local shops.'],
                    'internet_availability' => [8, 'Strong fiber coverage.'],
                    'road_quality' => [7, 'Well-paved main roads.'],
                    'noise' => [6, 'Moderate traffic noise on main roads.'],
                    'safety' => [8, 'Well-regarded residential/diplomatic area.'],
                    'flood_risk' => [8, 'Low flood history.'],
                    'rental_demand' => [8, 'High demand from professionals and diplomatic staff.'],
                    'development_activity' => [6, 'Steady but controlled development.'],
                ],
                'pois' => [
                    ['poi_type' => 'hospital', 'name' => 'Patan Hospital', 'lat' => 27.6737, 'lng' => 85.3157],
                    ['poi_type' => 'market', 'name' => 'Jawalakhel Chowk', 'lat' => 27.6744, 'lng' => 85.3134],
                ],
            ],
            'Lakeside' => [
                'is_curated' => true,
                'scores' => [
                    'transport_access' => [7, 'Well served by taxis; airport ~7km.'],
                    'schools' => [5, 'Mostly tourism-oriented; fewer schools directly lakeside.'],
                    'hospitals' => [6, 'Manipal Teaching Hospital within reach.'],
                    'markets' => [9, 'Dense tourist and grocery retail along the lake road.'],
                    'internet_availability' => [8, 'Strong coverage due to tourism demand.'],
                    'road_quality' => [7, 'Main lake road well maintained.'],
                    'noise' => [5, 'Lively nightlife strip near the lake.'],
                    'safety' => [7, 'Generally safe, well-patrolled tourist zone.'],
                    'flood_risk' => [6, 'Some low-lying areas near the lake shore.'],
                    'rental_demand' => [9, 'Very high short-let demand, strong long-term interest too.'],
                    'development_activity' => [8, 'Active hotel/guesthouse construction.'],
                ],
                'pois' => [
                    ['poi_type' => 'market', 'name' => 'Lakeside Road Market', 'lat' => 28.2096, 'lng' => 83.9556],
                    ['poi_type' => 'transport_stop', 'name' => 'Lakeside Taxi Stand', 'lat' => 28.2107, 'lng' => 83.9563],
                ],
            ],
        ];

        foreach ($curated as $name => $config) {
            $neighborhood = Neighborhood::query()->where('name', $name)->first();

            if (! $neighborhood) {
                continue;
            }

            $neighborhood->update(['is_curated' => true]);

            $overall = (int) round(collect($config['scores'])->avg(fn ($v) => $v[0]));

            $score = $neighborhood->score()->updateOrCreate([], [
                'overall_score' => $overall,
                'source' => 'admin_curated',
                'computed_at' => now(),
            ]);

            $score->factors()->delete();
            foreach ($config['scores'] as $key => [$points, $notes]) {
                $score->factors()->create([
                    'factor_key' => $key,
                    'score' => $points,
                    'data_source' => 'admin',
                    'notes' => $notes,
                ]);
            }

            $neighborhood->pois()->delete();
            foreach ($config['pois'] as $poi) {
                $neighborhood->pois()->create([...$poi, 'added_by' => $admin?->id, 'verified' => true]);
            }
        }
    }
}
