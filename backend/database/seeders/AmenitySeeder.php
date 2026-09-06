<?php

namespace Database\Seeders;

use App\Models\Amenity;
use Illuminate\Database\Seeder;

class AmenitySeeder extends Seeder
{
    public function run(): void
    {
        $amenities = [
            ['key' => 'parking', 'name' => 'Parking', 'name_ne' => 'पार्किङ', 'category' => 'convenience', 'icon' => 'car'],
            ['key' => 'lift', 'name' => 'Lift / Elevator', 'name_ne' => 'लिफ्ट', 'category' => 'convenience', 'icon' => 'arrow-up-down'],
            ['key' => 'generator', 'name' => 'Generator / Inverter backup', 'name_ne' => 'जेनेरेटर', 'category' => 'utilities', 'icon' => 'zap'],
            ['key' => 'water_tank', 'name' => 'Water tank / Borehole', 'name_ne' => 'पानी ट्यांकी', 'category' => 'utilities', 'icon' => 'droplet'],
            ['key' => 'solar_water_heater', 'name' => 'Solar water heater', 'name_ne' => 'सोलार हिटर', 'category' => 'utilities', 'icon' => 'sun'],
            ['key' => 'cctv', 'name' => 'CCTV', 'name_ne' => 'सीसीटीभी', 'category' => 'security', 'icon' => 'camera'],
            ['key' => 'security_guard', 'name' => 'Security guard', 'name_ne' => 'सुरक्षा गार्ड', 'category' => 'security', 'icon' => 'shield'],
            ['key' => 'earthquake_resistant', 'name' => 'Earthquake-resistant construction', 'name_ne' => 'भूकम्प प्रतिरोधी', 'category' => 'construction', 'icon' => 'shield-check'],
            ['key' => 'garden', 'name' => 'Garden', 'name_ne' => 'बगैंचा', 'category' => 'outdoor', 'icon' => 'flower'],
            ['key' => 'balcony', 'name' => 'Balcony', 'name_ne' => 'बालकनी', 'category' => 'outdoor', 'icon' => 'door-open'],
            ['key' => 'terrace', 'name' => 'Terrace', 'name_ne' => 'छत', 'category' => 'outdoor', 'icon' => 'home'],
            ['key' => 'internet_wifi', 'name' => 'Internet / Wi-Fi ready', 'name_ne' => 'इन्टरनेट', 'category' => 'utilities', 'icon' => 'wifi'],
            ['key' => 'store_room', 'name' => 'Store room', 'name_ne' => 'स्टोर रूम', 'category' => 'interior', 'icon' => 'box'],
            ['key' => 'servant_quarter', 'name' => 'Servant quarter', 'name_ne' => 'नोकर कोठा', 'category' => 'interior', 'icon' => 'users'],
            ['key' => 'kids_play_area', 'name' => "Kids' play area", 'name_ne' => 'बाल खेल क्षेत्र', 'category' => 'community', 'icon' => 'toy-brick'],
            ['key' => 'community_hall', 'name' => 'Community hall', 'name_ne' => 'सामुदायिक हल', 'category' => 'community', 'icon' => 'building-2'],
        ];

        foreach ($amenities as $amenity) {
            Amenity::query()->updateOrCreate(['key' => $amenity['key']], $amenity);
        }
    }
}
