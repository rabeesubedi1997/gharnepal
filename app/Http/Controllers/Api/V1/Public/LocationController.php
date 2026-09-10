<?php

namespace App\Http\Controllers\Api\V1\Public;

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
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class LocationController extends Controller
{
    public function provinces(): AnonymousResourceCollection
    {
        return ProvinceResource::collection(Province::orderBy('name')->get());
    }

    public function districts(Request $request): AnonymousResourceCollection
    {
        $query = District::query()->orderBy('name');

        if ($request->filled('province_id')) {
            $query->where('province_id', $request->integer('province_id'));
        }

        return DistrictResource::collection($query->get());
    }

    public function municipalities(Request $request): AnonymousResourceCollection
    {
        $query = Municipality::query()->orderBy('name');

        if ($request->filled('district_id')) {
            $query->where('district_id', $request->integer('district_id'));
        }

        return MunicipalityResource::collection($query->get());
    }

    public function wards(Request $request): AnonymousResourceCollection
    {
        $query = Ward::query()->orderBy('ward_number');

        if ($request->filled('municipality_id')) {
            $query->where('municipality_id', $request->integer('municipality_id'));
        }

        return WardResource::collection($query->get());
    }

    public function neighborhoods(Request $request): AnonymousResourceCollection
    {
        $query = Neighborhood::query()->orderBy('name');

        if ($request->filled('ward_id')) {
            $query->where('ward_id', $request->integer('ward_id'));
        }

        return NeighborhoodResource::collection($query->get());
    }
}
