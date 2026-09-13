<?php

namespace App\Http\Requests\Property;

use App\Domain\Calculators\Services\AreaUnitConverter;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdatePropertyRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'area_value' => ['sometimes', 'numeric', 'min:0.01'],
            'area_unit' => ['sometimes', Rule::in(AreaUnitConverter::units())],
            'bedrooms' => ['nullable', 'integer', 'min:0', 'max:50'],
            'bathrooms' => ['nullable', 'integer', 'min:0', 'max:50'],
            'floors' => ['nullable', 'integer', 'min:0', 'max:200'],
            'year_built' => ['nullable', 'integer', 'min:1900', 'max:' . (date('Y') + 1)],
            'parking_spaces' => ['nullable', 'integer', 'min:0', 'max:100'],
            'parking_type' => ['nullable', Rule::in(['car', 'bike', 'both'])],
            'is_furnished' => ['nullable', Rule::in(['unfurnished', 'semi', 'full'])],
            'facing_direction' => ['nullable', Rule::in(['north', 'south', 'east', 'west', 'northeast', 'northwest', 'southeast', 'southwest'])],
            'water_tank_capacity_liters' => ['nullable', 'integer', 'min:0', 'max:1000000'],
            'structural_notes' => ['nullable', 'string', 'max:1000'],

            'floor_breakdown' => ['nullable', 'array', 'max:20'],
            'floor_breakdown.*.label' => ['required', 'string', 'max:100'],
            'floor_breakdown.*.area_sqft' => ['nullable', 'numeric', 'min:0'],
            'floor_breakdown.*.description' => ['nullable', 'string', 'max:500'],

            'address' => ['sometimes', 'array'],
            'address.province_id' => ['required_with:address', 'integer', 'exists:provinces,id'],
            'address.district_id' => ['required_with:address', 'integer', 'exists:districts,id'],
            'address.municipality_id' => ['required_with:address', 'integer', 'exists:municipalities,id'],
            'address.ward_id' => ['required_with:address', 'integer', 'exists:wards,id'],
            'address.neighborhood_id' => ['nullable', 'integer', 'exists:neighborhoods,id'],
            'address.street_address' => ['nullable', 'string', 'max:255'],
            'address.landmark' => ['nullable', 'string', 'max:255'],
            'address.lat' => ['nullable', 'numeric', 'between:-90,90'],
            'address.lng' => ['nullable', 'numeric', 'between:-180,180'],
        ];
    }
}
