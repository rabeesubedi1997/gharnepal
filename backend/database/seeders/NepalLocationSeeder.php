<?php

namespace Database\Seeders;

use App\Models\District;
use App\Models\Municipality;
use App\Models\Neighborhood;
use App\Models\Province;
use App\Models\Ward;
use Illuminate\Database\Seeder;

/**
 * Seeds Nepal's real administrative hierarchy (Province > District > Municipality > Ward)
 * for the MVP launch cities only. Provinces/districts/municipalities/ward *counts* below
 * are official public facts. Expanding to more cities later is pure data-seeding — no
 * schema change needed.
 *
 * NOTE on neighborhoods: the named toles seeded at the bottom are real, well-known
 * neighborhoods, but their ward assignment here is a placeholder (attached to ward 1
 * of the municipality) and is NOT independently verified. Precise neighborhood-to-ward
 * mapping and boundary drawing is real admin content-ops work (see plan risk: OSM/location
 * data curation) and must be corrected by an admin with local knowledge before these are
 * treated as authoritative in the product.
 */
class NepalLocationSeeder extends Seeder
{
    public function run(): void
    {
        $bagmati = Province::query()->updateOrCreate(['code' => 'P3'], [
            'name' => 'Bagmati Province', 'name_ne' => 'बागमती प्रदेश',
        ]);
        $gandaki = Province::query()->updateOrCreate(['code' => 'P4'], [
            'name' => 'Gandaki Province', 'name_ne' => 'गण्डकी प्रदेश',
        ]);
        $koshi = Province::query()->updateOrCreate(['code' => 'P1'], [
            'name' => 'Koshi Province', 'name_ne' => 'कोशी प्रदेश',
        ]);

        $kathmanduDistrict = District::query()->updateOrCreate(['code' => 'D-KTM'], [
            'province_id' => $bagmati->id, 'name' => 'Kathmandu', 'name_ne' => 'काठमाडौं',
        ]);
        $lalitpurDistrict = District::query()->updateOrCreate(['code' => 'D-LTP'], [
            'province_id' => $bagmati->id, 'name' => 'Lalitpur', 'name_ne' => 'ललितपुर',
        ]);
        $bhaktapurDistrict = District::query()->updateOrCreate(['code' => 'D-BKT'], [
            'province_id' => $bagmati->id, 'name' => 'Bhaktapur', 'name_ne' => 'भक्तपुर',
        ]);
        $chitwanDistrict = District::query()->updateOrCreate(['code' => 'D-CTW'], [
            'province_id' => $bagmati->id, 'name' => 'Chitwan', 'name_ne' => 'चितवन',
        ]);
        $kaskiDistrict = District::query()->updateOrCreate(['code' => 'D-KSK'], [
            'province_id' => $gandaki->id, 'name' => 'Kaski', 'name_ne' => 'कास्की',
        ]);
        $morangDistrict = District::query()->updateOrCreate(['code' => 'D-MRG'], [
            'province_id' => $koshi->id, 'name' => 'Morang', 'name_ne' => 'मोरङ',
        ]);

        $municipalities = [
            [
                'district' => $kathmanduDistrict, 'code' => 'M-KTM', 'name' => 'Kathmandu Metropolitan City',
                'name_ne' => 'काठमाडौं महानगरपालिका', 'type' => 'metropolitan', 'ward_count' => 32,
                'neighborhoods' => ['Thamel', 'New Road', 'Baneshwor', 'Koteshwor', 'Kalanki', 'Boudha', 'Chabahil', 'Maharajgunj', 'Balaju', 'Gongabu'],
            ],
            [
                'district' => $lalitpurDistrict, 'code' => 'M-LTP', 'name' => 'Lalitpur Metropolitan City',
                'name_ne' => 'ललितपुर महानगरपालिका', 'type' => 'metropolitan', 'ward_count' => 29,
                'neighborhoods' => ['Patan Durbar Square / Mangal Bazar', 'Jawalakhel', 'Kupondole', 'Pulchowk', 'Sanepa', 'Ekantakuna'],
            ],
            [
                'district' => $bhaktapurDistrict, 'code' => 'M-BKT', 'name' => 'Bhaktapur Municipality',
                'name_ne' => 'भक्तपुर नगरपालिका', 'type' => 'municipality', 'ward_count' => 10,
                'neighborhoods' => ['Bhaktapur Durbar Square', 'Suryabinayak', 'Kamalbinayak'],
            ],
            [
                'district' => $chitwanDistrict, 'code' => 'M-BRT', 'name' => 'Bharatpur Metropolitan City',
                'name_ne' => 'भरतपुर महानगरपालिका', 'type' => 'metropolitan', 'ward_count' => 29,
                'neighborhoods' => ['Narayangarh', 'Bharatpur Chowk'],
            ],
            [
                'district' => $kaskiDistrict, 'code' => 'M-PKR', 'name' => 'Pokhara Metropolitan City',
                'name_ne' => 'पोखरा महानगरपालिका', 'type' => 'metropolitan', 'ward_count' => 33,
                'neighborhoods' => ['Lakeside', 'Chipledhunga', 'Mahendrapul', 'Bagar'],
            ],
            [
                'district' => $morangDistrict, 'code' => 'M-BRG', 'name' => 'Biratnagar Metropolitan City',
                'name_ne' => 'विराटनगर महानगरपालिका', 'type' => 'metropolitan', 'ward_count' => 19,
                'neighborhoods' => ['Traffic Chowk', 'Rani', 'Pandagachi'],
            ],
        ];

        foreach ($municipalities as $data) {
            $municipality = Municipality::query()->updateOrCreate(['code' => $data['code']], [
                'district_id' => $data['district']->id,
                'name' => $data['name'],
                'name_ne' => $data['name_ne'],
                'type' => $data['type'],
                'ward_count' => $data['ward_count'],
            ]);

            $wards = [];
            for ($n = 1; $n <= $data['ward_count']; $n++) {
                $wards[$n] = Ward::query()->updateOrCreate(
                    ['municipality_id' => $municipality->id, 'ward_number' => $n],
                );
            }

            // Placeholder attachment to ward 1 — see class docblock. Real mapping is
            // admin content-ops work, not something safe to assert precisely here.
            foreach ($data['neighborhoods'] as $name) {
                Neighborhood::query()->updateOrCreate(
                    ['ward_id' => $wards[1]->id, 'name' => $name],
                    ['is_curated' => false],
                );
            }
        }
    }
}
