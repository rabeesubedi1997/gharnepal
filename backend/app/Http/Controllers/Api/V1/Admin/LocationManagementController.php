<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\DistrictResource;
use App\Http\Resources\MunicipalityResource;
use App\Http\Resources\NeighborhoodResource;
use App\Http\Resources\ProvinceResource;
use App\Http\Resources\WardResource;
use App\Models\District;
use App\Models\Municipality;
use App\Models\Neighborhood;
use App\Models\Province;
use App\Models\Ward;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Validation\Rule;

class LocationManagementController extends Controller
{
    // -- Provinces --------------------------------------------------------

    public function storeProvince(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'name_ne' => ['nullable', 'string', 'max:255'],
            'code' => ['required', 'string', 'max:20', 'unique:provinces,code'],
        ]);

        return (new ProvinceResource(Province::create($data)))->response()->setStatusCode(201);
    }

    public function updateProvince(Request $request, Province $province): ProvinceResource
    {
        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'name_ne' => ['nullable', 'string', 'max:255'],
            'code' => ['sometimes', 'string', 'max:20', Rule::unique('provinces', 'code')->ignore($province->id)],
        ]);
        $province->update($data);

        return new ProvinceResource($province);
    }

    public function destroyProvince(Province $province): Response
    {
        $province->delete();

        return response()->noContent();
    }

    // -- Districts ----------------------------------------------------------

    public function storeDistrict(Request $request): JsonResponse
    {
        $data = $request->validate([
            'province_id' => ['required', 'exists:provinces,id'],
            'name' => ['required', 'string', 'max:255'],
            'name_ne' => ['nullable', 'string', 'max:255'],
            'code' => ['required', 'string', 'max:20', 'unique:districts,code'],
        ]);

        return (new DistrictResource(District::create($data)))->response()->setStatusCode(201);
    }

    public function updateDistrict(Request $request, District $district): DistrictResource
    {
        $data = $request->validate([
            'province_id' => ['sometimes', 'exists:provinces,id'],
            'name' => ['sometimes', 'string', 'max:255'],
            'name_ne' => ['nullable', 'string', 'max:255'],
            'code' => ['sometimes', 'string', 'max:20', Rule::unique('districts', 'code')->ignore($district->id)],
        ]);
        $district->update($data);

        return new DistrictResource($district);
    }

    public function destroyDistrict(District $district): Response
    {
        $district->delete();

        return response()->noContent();
    }

    // -- Municipalities -------------------------------------------------------

    public function storeMunicipality(Request $request): JsonResponse
    {
        $data = $request->validate([
            'district_id' => ['required', 'exists:districts,id'],
            'name' => ['required', 'string', 'max:255'],
            'name_ne' => ['nullable', 'string', 'max:255'],
            'type' => ['required', Rule::in(['metropolitan', 'sub_metropolitan', 'municipality', 'rural_municipality'])],
            'code' => ['required', 'string', 'max:20', 'unique:municipalities,code'],
            'ward_count' => ['required', 'integer', 'min:1', 'max:50'],
        ]);

        $municipality = Municipality::create($data);

        // Auto-provision wards 1..N so the municipality is immediately usable —
        // matches how NepalLocationSeeder seeds the MVP cities.
        for ($n = 1; $n <= $data['ward_count']; $n++) {
            Ward::firstOrCreate(['municipality_id' => $municipality->id, 'ward_number' => $n]);
        }

        return (new MunicipalityResource($municipality))->response()->setStatusCode(201);
    }

    public function updateMunicipality(Request $request, Municipality $municipality): MunicipalityResource
    {
        $data = $request->validate([
            'district_id' => ['sometimes', 'exists:districts,id'],
            'name' => ['sometimes', 'string', 'max:255'],
            'name_ne' => ['nullable', 'string', 'max:255'],
            'type' => ['sometimes', Rule::in(['metropolitan', 'sub_metropolitan', 'municipality', 'rural_municipality'])],
            'code' => ['sometimes', 'string', 'max:20', Rule::unique('municipalities', 'code')->ignore($municipality->id)],
        ]);
        $municipality->update($data);

        return new MunicipalityResource($municipality);
    }

    public function destroyMunicipality(Municipality $municipality): Response
    {
        $municipality->delete();

        return response()->noContent();
    }

    // -- Wards ------------------------------------------------------------

    public function storeWard(Request $request): JsonResponse
    {
        $data = $request->validate([
            'municipality_id' => ['required', 'exists:municipalities,id'],
            'ward_number' => ['required', 'integer', 'min:1', 'max:50'],
            'name' => ['nullable', 'string', 'max:255'],
        ]);

        return (new WardResource(Ward::create($data)))->response()->setStatusCode(201);
    }

    public function destroyWard(Ward $ward): Response
    {
        $ward->delete();

        return response()->noContent();
    }

    // -- Neighborhoods ------------------------------------------------------

    public function storeNeighborhood(Request $request): JsonResponse
    {
        $data = $request->validate([
            'ward_id' => ['required', 'exists:wards,id'],
            'name' => ['required', 'string', 'max:255'],
            'name_ne' => ['nullable', 'string', 'max:255'],
            'centroid_lat' => ['nullable', 'numeric', 'between:-90,90'],
            'centroid_lng' => ['nullable', 'numeric', 'between:-180,180'],
        ]);
        $data['is_curated'] = true; // an admin entering it by hand is exactly what "curated" means

        return (new NeighborhoodResource(Neighborhood::create($data)))->response()->setStatusCode(201);
    }

    public function updateNeighborhood(Request $request, Neighborhood $neighborhood): NeighborhoodResource
    {
        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'name_ne' => ['nullable', 'string', 'max:255'],
            'centroid_lat' => ['nullable', 'numeric', 'between:-90,90'],
            'centroid_lng' => ['nullable', 'numeric', 'between:-180,180'],
            'is_curated' => ['sometimes', 'boolean'],
        ]);
        $neighborhood->update($data);

        return new NeighborhoodResource($neighborhood);
    }

    public function destroyNeighborhood(Neighborhood $neighborhood): Response
    {
        $neighborhood->delete();

        return response()->noContent();
    }
}
