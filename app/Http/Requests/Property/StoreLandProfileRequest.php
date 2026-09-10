<?php

namespace App\Http\Requests\Property;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreLandProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'kitta_number' => ['nullable', 'string', 'max:100'],
            'lalpurja_available' => ['sometimes', Rule::in(['yes', 'no', 'in_process', 'unknown'])],

            'road_access' => ['sometimes', 'boolean'],
            'road_width_meters' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'road_type' => ['sometimes', Rule::in(['blacktop', 'gravel', 'dirt', 'none'])],

            'water_access' => ['sometimes', Rule::in(['municipal', 'well', 'none', 'unknown'])],
            'electricity_access' => ['sometimes', 'boolean'],
            'drainage_access' => ['sometimes', Rule::in(['yes', 'no', 'unknown'])],

            'land_classification' => ['sometimes', Rule::in(['residential', 'agricultural', 'commercial', 'guthi', 'other'])],
            'flood_risk' => ['sometimes', Rule::in(['none', 'low', 'medium', 'high', 'unknown'])],
            'landslide_risk' => ['sometimes', Rule::in(['none', 'low', 'medium', 'high', 'unknown'])],
            'nearby_development_notes' => ['nullable', 'string', 'max:2000'],
        ];
    }
}
