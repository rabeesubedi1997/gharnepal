<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Agency;
use App\Models\CommunityNote;
use App\Models\DuplicateListingFlag;
use App\Models\ListingReport;
use App\Models\PaymentTransaction;
use App\Models\PropertyListing;
use App\Models\Role;
use App\Models\User;
use App\Models\UserVerification;
use Illuminate\Http\JsonResponse;

/**
 * Every figure here is a real, live query — never a hardcoded or sampled
 * number. If a count looks wrong, the underlying data is wrong; there is no
 * separate "display" number to keep in sync.
 */
class DashboardController extends Controller
{
    public function stats(): JsonResponse
    {
        return response()->json(['data' => [
            'listings' => [
                'total' => PropertyListing::count(),
                'published' => PropertyListing::where('status', PropertyListing::STATUS_PUBLISHED)->count(),
                'pending_review' => PropertyListing::where('status', PropertyListing::STATUS_PENDING_REVIEW)->count(),
                'featured_active' => PropertyListing::whereNotNull('featured_until')->where('featured_until', '>', now())->count(),
            ],
            'users' => [
                'total' => User::count(),
                'owners' => User::whereHas('roles', fn ($q) => $q->where('key', Role::OWNER))->count(),
                'agents' => User::whereHas('roles', fn ($q) => $q->where('key', Role::AGENT))->count(),
                'suspended' => User::where('status', 'suspended')->count(),
            ],
            'agencies' => [
                'total' => Agency::count(),
                'verified' => Agency::whereNotNull('verified_at')->count(),
                'pending' => Agency::where('status', 'pending')->count(),
            ],
            'moderation_queue' => [
                'reports' => ListingReport::where('status', 'open')->count(),
                'duplicate_flags' => DuplicateListingFlag::where('status', 'unreviewed')->count(),
                'verifications' => UserVerification::where('status', 'pending')->count(),
                'community_notes' => CommunityNote::where('status', 'pending')->count(),
            ],
            'payments' => [
                'completed_count' => PaymentTransaction::where('status', 'completed')->count(),
                'completed_amount' => (float) PaymentTransaction::where('status', 'completed')->sum('amount'),
                'pending' => PaymentTransaction::where('status', 'pending')->count(),
            ],
        ]]);
    }
}
