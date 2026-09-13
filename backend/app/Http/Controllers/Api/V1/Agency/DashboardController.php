<?php

namespace App\Http\Controllers\Api\V1\Agency;

use App\Domain\Agencies\Services\AgencyDashboardService;
use App\Http\Controllers\Controller;
use App\Http\Resources\Agency\AgencyListingRowResource;
use App\Models\Agency;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

/**
 * A self-service dashboard for an agency's own members — every figure is a
 * real query against this agency's own listings/conversations/viewing
 * requests. Deliberately does not attempt: a WhatsApp-vs-portal inquiry
 * channel split (only one channel — this platform's own messaging — is
 * ever tracked), a weekly-digest open-rate (no email-open tracking
 * exists), or an "NRI buyer match index" (no diaspora/nationality field
 * exists anywhere in this schema, and inventing one to demo a chart would
 * be exactly the kind of fabricated metric this rebuild set out to avoid).
 */
class DashboardController extends Controller
{
    public function __construct(private readonly AgencyDashboardService $dashboard) {}

    /** A user can belong to more than one agency in principle, but no part
     * of this product has ever had to handle that yet — every seed account
     * and every real signup so far belongs to exactly one. Takes the first
     * membership rather than building multi-agency switching now. */
    private function agencyFor(Request $request): Agency
    {
        $agency = $request->user()->agencies()->first();

        if (! $agency) {
            throw new NotFoundHttpException('You are not a member of any agency.');
        }

        return $agency;
    }

    public function overview(Request $request): JsonResponse
    {
        $agency = $this->agencyFor($request);

        return response()->json([
            'data' => [
                'agency' => [
                    'name' => $agency->name,
                    'slug' => $agency->slug,
                    'logo_url' => $agency->logo_path ? \Illuminate\Support\Facades\Storage::disk('public')->url($agency->logo_path) : null,
                    'registration_number' => $agency->registration_number,
                    'founded_year' => $agency->founded_year,
                    'is_verified' => $agency->isVerified(),
                    'member_count' => $agency->members()->count(),
                ],
                ...$this->dashboard->overview($agency),
            ],
        ]);
    }

    public function listings(Request $request): AnonymousResourceCollection
    {
        $agency = $this->agencyFor($request);

        $validated = $request->validate([
            'category' => ['nullable', Rule::in(['houses', 'land', 'commercial'])],
            'search' => ['nullable', 'string', 'max:255'],
            'sort' => ['nullable', Rule::in(['newest', 'leads', 'price_high', 'price_low'])],
        ]);

        $listings = $this->dashboard->listings(
            $agency,
            $validated['category'] ?? null,
            $validated['search'] ?? null,
            $validated['sort'] ?? 'newest',
        );

        return AgencyListingRowResource::collection($listings);
    }

    public function inquiries(Request $request): JsonResponse
    {
        $agency = $this->agencyFor($request);
        $conversations = $this->dashboard->inquiries($agency);

        return response()->json([
            'data' => $conversations->map(fn ($c) => [
                'id' => $c->id,
                'buyer_name' => $c->buyer?->name,
                'listing_title' => $c->listing?->title,
                'listing_slug' => $c->listing?->slug,
                'last_message_at' => $c->last_message_at,
                'message_count' => (int) $c->messages_count,
            ]),
        ]);
    }

    public function siteVisits(Request $request): JsonResponse
    {
        $agency = $this->agencyFor($request);
        $visits = $this->dashboard->upcomingSiteVisits($agency);

        return response()->json([
            'data' => $visits->map(fn ($v) => [
                'id' => $v->id,
                'when' => ($v->confirmed_datetime ?? $v->proposed_datetime)?->toIso8601String(),
                'is_confirmed' => $v->confirmed_datetime !== null,
                'listing_title' => $v->listing?->title,
                'listing_slug' => $v->listing?->slug,
                'municipality' => $v->listing?->property?->address?->municipality?->name,
                'requester_name' => $v->requester?->name,
            ]),
        ]);
    }
}
