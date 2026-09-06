<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Domain\Trust\Services\TrustScoreCalculator;
use App\Http\Controllers\Controller;
use App\Http\Resources\ListingReportResource;
use App\Models\ListingReport;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class ReportModerationController extends Controller
{
    public function __construct(private readonly TrustScoreCalculator $trustScoreCalculator) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $status = $request->string('status', 'open')->toString();

        $reports = ListingReport::query()
            ->where('status', $status)
            ->with(['listing', 'reportedBy'])
            ->latest()
            ->paginate(20);

        return ListingReportResource::collection($reports);
    }

    public function resolve(Request $request, ListingReport $report): ListingReportResource
    {
        $data = $request->validate([
            'status' => ['required', Rule::in(['reviewed', 'dismissed', 'action_taken'])],
            'resolution_note' => ['nullable', 'string', 'max:1000'],
        ]);

        $report->update([
            'status' => $data['status'],
            'resolution_note' => $data['resolution_note'] ?? null,
            'reviewed_by' => $request->user()->id,
        ]);

        if ($report->listing) {
            $this->trustScoreCalculator->recompute($report->listing);
        }

        return new ListingReportResource($report->load(['listing', 'reportedBy']));
    }
}
