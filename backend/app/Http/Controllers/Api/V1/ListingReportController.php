<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ListingReportResource;
use App\Models\ListingReport;
use App\Models\PropertyListing;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ListingReportController extends Controller
{
    public function store(Request $request, PropertyListing $listing): JsonResponse
    {
        $data = $request->validate([
            'reason' => ['required', Rule::in(['fraud', 'duplicate', 'sold_already', 'misleading', 'inappropriate', 'other'])],
            'details' => ['nullable', 'string', 'max:1000'],
        ]);

        $report = ListingReport::create([
            'property_listing_id' => $listing->id,
            'reported_by' => $request->user()->id,
            'reason' => $data['reason'],
            'details' => $data['details'] ?? null,
            'status' => 'open',
        ]);

        return (new ListingReportResource($report->load('listing')))->response()->setStatusCode(201);
    }
}
