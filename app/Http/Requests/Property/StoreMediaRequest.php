<?php

namespace App\Http\Requests\Property;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreMediaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'type' => ['required', Rule::in(['image', 'video', 'floor_plan', 'document'])],
            'file' => [
                'required',
                'file',
                'max:20480', // 20MB
                Rule::when($this->input('type') === 'image', ['mimes:jpg,jpeg,png,webp']),
                Rule::when($this->input('type') === 'video', ['mimes:mp4,mov,webm']),
                Rule::when(in_array($this->input('type'), ['floor_plan', 'document'], true), ['mimes:jpg,jpeg,png,pdf']),
            ],
        ];
    }
}
