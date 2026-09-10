<?php

namespace App\Http\Controllers\Api\V1\Public;

use App\Http\Controllers\Controller;
use App\Http\Resources\AmenityResource;
use App\Models\Amenity;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class AmenityController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        return AmenityResource::collection(Amenity::orderBy('category')->orderBy('name')->get());
    }
}
