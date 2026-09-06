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
