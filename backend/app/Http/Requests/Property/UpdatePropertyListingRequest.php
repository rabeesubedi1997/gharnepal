<?php

namespace App\Http\Requests\Property;

use App\Domain\Properties\Support\VideoUrl;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdatePropertyListingRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'price' => ['sometimes', 'numeric', 'min:1'],
            'price_period' => ['nullable', Rule::in(['total', 'monthly'])],
            'negotiable' => ['sometimes', 'boolean'],
            'availability_date' => ['nullable', 'date'],
            'title' => ['sometimes', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:5000'],
            'amenity_ids' => ['sometimes', 'array'],
            'amenity_ids.*' => ['integer', 'exists:amenities,id'],
            'video_url' => [
                'nullable', 'string', 'url', 'max:500',
                function (string $attribute, mixed $value, \Closure $fail) {
                    if ($value && ! VideoUrl::isSupported($value)) {
                        $fail('Enter a YouTube or Vimeo link.');
                    }
                },
            ],
        ];
    }
}
