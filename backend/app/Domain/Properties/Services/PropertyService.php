<?php

namespace App\Domain\Properties\Services;

use App\Domain\Calculators\Services\AreaUnitConverter;
use App\Models\Address;
use App\Models\Property;
use App\Models\Role;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class PropertyService
{
    /**
     * Creates a property + its address in one transaction, and makes the
     * creator its owner (auto-granting the `owner` role on first post, the
     * same low-friction pattern used for `buyer` on registration).
     */
    public function createForUser(User $user, array $data): Property
    {
        return DB::transaction(function () use ($user, $data) {
            $property = Property::create([
                'owner_user_id' => $user->id,
                'created_by' => $user->id,
                'property_type' => $data['property_type'],
                'total_area_value_entered' => $data['area_value'],
                'total_area_unit_entered' => $data['area_unit'],
                'total_area_sqm' => AreaUnitConverter::toSqm((float) $data['area_value'], $data['area_unit']),
                'bedrooms' => $data['bedrooms'] ?? null,
                'bathrooms' => $data['bathrooms'] ?? null,
                'floors' => $data['floors'] ?? null,
                'year_built' => $data['year_built'] ?? null,
                'parking_spaces' => $data['parking_spaces'] ?? 0,
                'parking_type' => $data['parking_type'] ?? null,
                'is_furnished' => $data['is_furnished'] ?? null,
            ]);

            $this->putAddress($property, $data['address']);

            $property->managers()->syncWithoutDetaching([$user->id => ['relation' => 'owner']]);

            $user->roles()->syncWithoutDetaching(Role::where('key', Role::OWNER)->pluck('id'));

            return $property->fresh(['address.province', 'address.district', 'address.municipality', 'address.ward', 'address.neighborhood']);
        });
    }

    public function update(Property $property, array $data): Property
    {
        $areaFields = [];

        if (isset($data['area_value'], $data['area_unit'])) {
            $areaFields = [
                'total_area_value_entered' => $data['area_value'],
                'total_area_unit_entered' => $data['area_unit'],
                'total_area_sqm' => AreaUnitConverter::toSqm((float) $data['area_value'], $data['area_unit']),
            ];
        }

        $property->update(array_filter([
            ...$areaFields,
            'bedrooms' => $data['bedrooms'] ?? null,
            'bathrooms' => $data['bathrooms'] ?? null,
            'floors' => $data['floors'] ?? null,
            'year_built' => $data['year_built'] ?? null,
            'parking_spaces' => $data['parking_spaces'] ?? null,
            'parking_type' => $data['parking_type'] ?? null,
            'is_furnished' => $data['is_furnished'] ?? null,
        ], fn ($v) => $v !== null));

        if (isset($data['address'])) {
            $this->putAddress($property, $data['address']);
        }

        return $property->fresh(['address.province', 'address.district', 'address.municipality', 'address.ward', 'address.neighborhood']);
    }

    private function putAddress(Property $property, array $addressData): Address
    {
        return $property->address()->updateOrCreate([], [
            'province_id' => $addressData['province_id'],
            'district_id' => $addressData['district_id'],
            'municipality_id' => $addressData['municipality_id'],
            'ward_id' => $addressData['ward_id'],
            'neighborhood_id' => $addressData['neighborhood_id'] ?? null,
            'street_address' => $addressData['street_address'] ?? null,
            'landmark' => $addressData['landmark'] ?? null,
            'lat' => $addressData['lat'] ?? null,
            'lng' => $addressData['lng'] ?? null,
        ]);
    }
}
