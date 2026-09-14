<?php

use App\Http\Controllers\Api\V1\Account\CalculatorScenarioController;
use App\Http\Controllers\Api\V1\Account\FavoriteCollectionController;
use App\Http\Controllers\Api\V1\Account\FavoriteController;
use App\Http\Controllers\Api\V1\Public\FavoriteCollectionController as PublicFavoriteCollectionController;
use App\Http\Controllers\Api\V1\Account\MatchPreferenceController;
use App\Http\Controllers\Api\V1\Account\MatchResultController;
use App\Http\Controllers\Api\V1\Account\PhoneVerificationController;
use App\Http\Controllers\Api\V1\Account\ProfileController;
use App\Http\Controllers\Api\V1\Account\SavedSearchController;
use App\Http\Controllers\Api\V1\Account\VerificationController;
use App\Http\Controllers\Api\V1\Agency\DashboardController as AgencyDashboardController;
use App\Http\Controllers\Api\V1\Admin\AdvertisementController as AdminAdvertisementController;
use App\Http\Controllers\Api\V1\Admin\AgencyController as AdminAgencyController;
use App\Http\Controllers\Api\V1\Admin\AmenityController as AdminAmenityController;
use App\Http\Controllers\Api\V1\Admin\BannerController as AdminBannerController;
use App\Http\Controllers\Api\V1\Admin\BlogPostController as AdminBlogPostController;
use App\Http\Controllers\Api\V1\Admin\BrandingController as AdminBrandingController;
use App\Http\Controllers\Api\V1\Admin\SecurityController as AdminSecurityController;
use App\Http\Controllers\Api\V1\Admin\CommunityNoteModerationController;
use App\Http\Controllers\Api\V1\Admin\ConversationController as AdminConversationController;
use App\Http\Controllers\Api\V1\Admin\DashboardController;
use App\Http\Controllers\Api\V1\Admin\DuplicateFlagController;
use App\Http\Controllers\Api\V1\Admin\ListingModerationController;
use App\Http\Controllers\Api\V1\Admin\MailTestController;
use App\Http\Controllers\Api\V1\Admin\LocationManagementController;
use App\Http\Controllers\Api\V1\Admin\NeighborhoodPoiController;
use App\Http\Controllers\Api\V1\Admin\NeighborhoodScoreController;
use App\Http\Controllers\Api\V1\Admin\PaymentController as AdminPaymentController;
use App\Http\Controllers\Api\V1\Admin\ReportModerationController;
use App\Http\Controllers\Api\V1\Admin\TrustOverrideController;
use App\Http\Controllers\Api\V1\Admin\TrustScoreFactorController;
use App\Http\Controllers\Api\V1\Admin\UserController as AdminUserController;
use App\Http\Controllers\Api\V1\Admin\VerificationModerationController;
use App\Http\Controllers\Api\V1\Account\PushSubscriptionController;
use App\Http\Controllers\Api\V1\Auth\AuthController;
use App\Http\Controllers\Api\V1\Auth\PasswordResetController;
use App\Http\Controllers\Api\V1\CommunityNoteController;
use App\Http\Controllers\Api\V1\CostCalculatorController;
use App\Http\Controllers\Api\V1\ListingReportController;
use App\Http\Controllers\Api\V1\Messaging\ConversationController;
use App\Http\Controllers\Api\V1\Messaging\MessageController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\PropertyRequestController;
use App\Http\Controllers\Api\V1\RatingController;
use App\Http\Controllers\Api\V1\Admin\RatingController as AdminRatingController;
use App\Http\Controllers\Api\V1\Admin\SeoController as AdminSeoController;
use App\Http\Controllers\Api\V1\Owner\FeaturedListingController;
use App\Http\Controllers\Api\V1\Owner\LandProfileController;
use App\Http\Controllers\Api\V1\Owner\ListingAnalyticsController;
use App\Http\Controllers\Api\V1\Owner\MediaController;
use App\Http\Controllers\Api\V1\Owner\PaymentController as OwnerPaymentController;
use App\Http\Controllers\Api\V1\Owner\PropertyController;
use App\Http\Controllers\Api\V1\Owner\PropertyListingController;
use App\Http\Controllers\Api\V1\Public\AdvertisementController;
use App\Http\Controllers\Api\V1\Public\AgencyController;
use App\Http\Controllers\Api\V1\Public\AmenityController;
use App\Http\Controllers\Api\V1\Public\BannerController;
use App\Http\Controllers\Api\V1\Public\BrandingController;
use App\Http\Controllers\Api\V1\Public\SecurityController;
use App\Http\Controllers\Api\V1\Public\BlogController;
use App\Http\Controllers\Api\V1\Public\ListingController;
use App\Http\Controllers\Api\V1\Public\PlatformStatsController;
use App\Http\Controllers\Api\V1\Public\LocationController;
use App\Http\Controllers\Api\V1\Public\NeighborhoodController;
use App\Http\Controllers\Api\V1\Public\PushConfigController;
use App\Http\Controllers\Api\V1\Public\SeoController;
use App\Http\Controllers\Api\V1\ViewingRequestController;
use App\Http\Controllers\Api\V1\VisitVerificationController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::prefix('locations')->group(function () {
        Route::get('provinces', [LocationController::class, 'provinces']);
        Route::get('districts', [LocationController::class, 'districts']);
        Route::get('municipalities', [LocationController::class, 'municipalities']);
        Route::get('wards', [LocationController::class, 'wards']);
        Route::get('neighborhoods', [LocationController::class, 'neighborhoods']);
    });

    Route::prefix('auth')->group(function () {
        Route::middleware('throttle:auth')->group(function () {
            Route::post('register', [AuthController::class, 'register']);
            Route::post('login', [AuthController::class, 'login']);
            Route::post('password/forgot', [PasswordResetController::class, 'sendResetLink']);
            Route::post('password/reset', [PasswordResetController::class, 'reset']);
        });

        Route::middleware('auth:sanctum')->group(function () {
            Route::post('logout', [AuthController::class, 'logout']);
            Route::get('me', [AuthController::class, 'me']);
        });
    });

    Route::middleware('auth:sanctum')->prefix('account')->group(function () {
        Route::put('profile', [ProfileController::class, 'update']);
        Route::put('password', [ProfileController::class, 'updatePassword']);

        Route::post('phone/request-otp', [PhoneVerificationController::class, 'requestOtp'])->middleware('throttle:otp-request');
        Route::post('phone/verify-otp', [PhoneVerificationController::class, 'verifyOtp'])->middleware('throttle:otp-verify');

        Route::get('favorites', [FavoriteController::class, 'index']);
        Route::post('favorites', [FavoriteController::class, 'store']);
        Route::put('favorites/{listing}', [FavoriteController::class, 'move']);
        Route::delete('favorites/{listing}', [FavoriteController::class, 'destroy']);

        Route::get('favorite-collections', [FavoriteCollectionController::class, 'index']);
        Route::post('favorite-collections', [FavoriteCollectionController::class, 'store']);
        Route::put('favorite-collections/{collection}', [FavoriteCollectionController::class, 'update']);
        Route::delete('favorite-collections/{collection}', [FavoriteCollectionController::class, 'destroy']);

        Route::get('saved-searches', [SavedSearchController::class, 'index']);
        Route::post('saved-searches', [SavedSearchController::class, 'store']);
        Route::put('saved-searches/{savedSearch}', [SavedSearchController::class, 'update']);
        Route::delete('saved-searches/{savedSearch}', [SavedSearchController::class, 'destroy']);

        Route::get('verifications', [VerificationController::class, 'index']);
        Route::post('verifications', [VerificationController::class, 'store']);

        Route::get('calculator-scenarios', [CalculatorScenarioController::class, 'index']);
        Route::delete('calculator-scenarios/{scenario}', [CalculatorScenarioController::class, 'destroy']);

        Route::get('match-preferences', [MatchPreferenceController::class, 'show']);
        Route::put('match-preferences', [MatchPreferenceController::class, 'store']);
        Route::get('match-results', [MatchResultController::class, 'index']);
        Route::post('match-results/refresh', [MatchResultController::class, 'refresh']);
    });

    // Agency self-service dashboard — any member (owner_admin or agent) of
    // the requesting user's own agency. 404s (not 403) for a user with no
    // agency membership at all, since there is nothing to "forbid" here.
    Route::middleware('auth:sanctum')->prefix('agency/dashboard')->group(function () {
        Route::get('overview', [AgencyDashboardController::class, 'overview']);
        Route::get('listings', [AgencyDashboardController::class, 'listings']);
        Route::get('inquiries', [AgencyDashboardController::class, 'inquiries']);
        Route::get('site-visits', [AgencyDashboardController::class, 'siteVisits']);
    });

    // Web push — public key so the frontend can build a subscription;
    // subscribe/unsubscribe are per-account.
    Route::get('push/vapid-public-key', [PushConfigController::class, 'vapidPublicKey']);
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('account/push-subscriptions', [PushSubscriptionController::class, 'store']);
        Route::delete('account/push-subscriptions', [PushSubscriptionController::class, 'destroy']);
    });

    // Public listing search & detail
    Route::get('listings', [ListingController::class, 'index']);
    Route::get('listings/{slug}', [ListingController::class, 'show']);
    Route::get('amenities', [AmenityController::class, 'index']);
    Route::get('platform-stats', [PlatformStatsController::class, 'index']);

    // Shared favorite collections — public, unguessable-token read access, no auth.
    Route::get('collections/{token}', [PublicFavoriteCollectionController::class, 'show']);

    // Ratings — reading is public, submitting/removing is authenticated
    Route::get('listings/{listing}/ratings', [RatingController::class, 'index']);
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('listings/{listing}/ratings', [RatingController::class, 'store']);
        Route::delete('listings/{listing}/ratings', [RatingController::class, 'destroy']);
    });

    // Public agent/agency directory
    Route::get('agencies', [AgencyController::class, 'index']);
    Route::get('agencies/{slug}', [AgencyController::class, 'show']);

    // Property requests — a demand-side board (buyers post what they want).
    // Listing open requests is public; posting/closing one's own is not.
    Route::get('property-requests', [PropertyRequestController::class, 'index']);
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('property-requests', [PropertyRequestController::class, 'store']);
        Route::patch('property-requests/{propertyRequest}/close', [PropertyRequestController::class, 'close']);
        Route::get('account/property-requests', [PropertyRequestController::class, 'mine']);
    });

    // Homepage banners
    Route::get('banners', [BannerController::class, 'index']);

    // Site branding (name, favicon, mobile app icon source) — admin-editable.
    Route::get('branding', [BrandingController::class, 'show']);

    // Whether to render the "I'm not a robot" widget on registration, and with which site key.
    Route::get('security/captcha', [SecurityController::class, 'captcha']);

    // Advertisements — targeted ad slots across pages (see AdvertisementPlacement)
    Route::get('advertisements', [AdvertisementController::class, 'index']);

    // Blog — real content pages for SEO
    Route::get('blog', [BlogController::class, 'index']);
    Route::get('blog/{slug}', [BlogController::class, 'show']);

    // Effective (override-merged) SEO metadata for static/category pages —
    // listing/neighborhood/agency SEO rides along inside their own detail resource.
    Route::get('seo/pages/{key}', [SeoController::class, 'page']);

    // Cost calculators — stateless; optionally persisted if the caller is authenticated
    Route::post('calculators/rental', [CostCalculatorController::class, 'rental']);
    Route::post('calculators/purchase', [CostCalculatorController::class, 'purchase']);

    // Featured-listing boost pricing — public, static catalog
    Route::get('featured-plans', [FeaturedListingController::class, 'plans']);

    // Neighborhood profiles & community notes
    Route::get('neighborhoods', [NeighborhoodController::class, 'index']);
    Route::get('neighborhoods/{neighborhood}', [NeighborhoodController::class, 'show']);
    Route::middleware('auth:sanctum')->post('neighborhoods/{neighborhood}/community-notes', [CommunityNoteController::class, 'store']);

    // Owner / agent: property + listing management
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('owner/properties', [PropertyController::class, 'index']);
        Route::post('properties', [PropertyController::class, 'store']);
        Route::get('properties/{property}', [PropertyController::class, 'show']);
        Route::put('properties/{property}', [PropertyController::class, 'update']);

        Route::post('properties/{property}/media', [MediaController::class, 'store']);
        Route::delete('properties/{property}/media/{media}', [MediaController::class, 'destroy']);

        Route::post('properties/{property}/listings', [PropertyListingController::class, 'store']);
        Route::get('owner/listings/{listing}', [PropertyListingController::class, 'show']);
        Route::put('owner/listings/{listing}', [PropertyListingController::class, 'update']);
        Route::patch('owner/listings/{listing}/transition', [PropertyListingController::class, 'transition']);
        Route::get('owner/listings/{listing}/analytics', [ListingAnalyticsController::class, 'show']);

        Route::get('properties/{property}/land-profile', [LandProfileController::class, 'show']);
        Route::put('properties/{property}/land-profile', [LandProfileController::class, 'store']);
        Route::post('properties/{property}/land-profile/document', [LandProfileController::class, 'uploadDocument']);

        Route::post('listings/{listing}/reports', [ListingReportController::class, 'store']);

        Route::post('listings/{listing}/feature', [FeaturedListingController::class, 'store']);
        Route::get('account/payments', [OwnerPaymentController::class, 'index']);
        Route::post('account/payments/{transaction}/confirm', [OwnerPaymentController::class, 'confirm']);
    });

    // Messaging
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('conversations', [ConversationController::class, 'index']);
        Route::post('conversations', [ConversationController::class, 'store']);
        Route::get('conversations/{conversation}', [ConversationController::class, 'show']);
        Route::post('conversations/{conversation}/messages', [MessageController::class, 'store']);
    });

    // Viewing requests
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('viewing-requests', [ViewingRequestController::class, 'index']);
        Route::post('viewing-requests', [ViewingRequestController::class, 'store']);
        Route::patch('viewing-requests/{viewingRequest}/transition', [ViewingRequestController::class, 'transition']);
        Route::post('viewing-requests/{viewingRequest}/visit-verification', [VisitVerificationController::class, 'store']);
    });

    // Notifications
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('notifications', [NotificationController::class, 'index']);
        Route::patch('notifications/{id}/read', [NotificationController::class, 'markRead']);
        Route::patch('notifications/read-all', [NotificationController::class, 'markAllRead']);
    });

    // Admin moderation
    Route::middleware(['auth:sanctum', 'admin'])->prefix('admin')->group(function () {
        Route::get('dashboard/stats', [DashboardController::class, 'stats']);

        Route::get('users', [AdminUserController::class, 'index']);
        Route::post('users', [AdminUserController::class, 'store']);
        Route::patch('users/{user}/status', [AdminUserController::class, 'updateStatus']);
        Route::put('users/{user}/roles', [AdminUserController::class, 'updateRoles']);

        Route::get('agencies', [AdminAgencyController::class, 'index']);
        Route::patch('agencies/{agency}/verify', [AdminAgencyController::class, 'verify']);
        Route::patch('agencies/{agency}/suspend', [AdminAgencyController::class, 'suspend']);

        Route::get('amenities', [AdminAmenityController::class, 'index']);
        Route::post('amenities', [AdminAmenityController::class, 'store']);
        Route::put('amenities/{amenity}', [AdminAmenityController::class, 'update']);
        Route::delete('amenities/{amenity}', [AdminAmenityController::class, 'destroy']);

        Route::get('listings', [ListingModerationController::class, 'index']);
        Route::patch('listings/{listing}/approve', [ListingModerationController::class, 'approve']);
        Route::patch('listings/{listing}/reject', [ListingModerationController::class, 'reject']);

        Route::get('reports', [ReportModerationController::class, 'index']);
        Route::patch('reports/{report}/resolve', [ReportModerationController::class, 'resolve']);

        Route::get('duplicate-flags', [DuplicateFlagController::class, 'index']);
        Route::patch('duplicate-flags/{duplicateFlag}/confirm', [DuplicateFlagController::class, 'confirm']);
        Route::patch('duplicate-flags/{duplicateFlag}/dismiss', [DuplicateFlagController::class, 'dismiss']);

        Route::get('verifications', [VerificationModerationController::class, 'index']);
        Route::patch('verifications/{verification}/approve', [VerificationModerationController::class, 'approve']);
        Route::patch('verifications/{verification}/reject', [VerificationModerationController::class, 'reject']);

        Route::post('listings/{listing}/trust-override', [TrustOverrideController::class, 'store']);
        Route::delete('listings/{listing}/trust-override', [TrustOverrideController::class, 'destroy']);

        Route::get('trust-score-factors', [TrustScoreFactorController::class, 'index']);
        Route::put('trust-score-factors/{trustScoreFactor}', [TrustScoreFactorController::class, 'update']);

        Route::patch('properties/{property}/land-profile/verify', [LandProfileController::class, 'verify']);

        Route::post('neighborhoods/{neighborhood}/score', [NeighborhoodScoreController::class, 'store']);
        Route::post('neighborhoods/{neighborhood}/pois', [NeighborhoodPoiController::class, 'store']);
        Route::delete('neighborhood-pois/{poi}', [NeighborhoodPoiController::class, 'destroy']);

        Route::get('community-notes', [CommunityNoteModerationController::class, 'index']);
        Route::patch('community-notes/{note}/approve', [CommunityNoteModerationController::class, 'approve']);
        Route::patch('community-notes/{note}/reject', [CommunityNoteModerationController::class, 'reject']);

        Route::get('payments', [AdminPaymentController::class, 'index']);
        // Refunding real money is reserved to a super admin even though any
        // admin can see the transaction list.
        Route::patch('payments/{transaction}/refund', [AdminPaymentController::class, 'refund'])->middleware('super_admin');

        // SEO — "page approach": one page_key per page, override + competitor-scan history.
        // page_key contains a colon (e.g. "listing:some-slug") — Laravel's default route
        // parameter pattern ([^/]+) already allows that without a custom regex.
        Route::get('seo/pages', [AdminSeoController::class, 'index']);
        Route::get('seo/pages/{key}', [AdminSeoController::class, 'show']);
        Route::put('seo/pages/{key}', [AdminSeoController::class, 'update']);
        Route::delete('seo/pages/{key}', [AdminSeoController::class, 'destroy']);
        Route::post('seo/pages/{key}/scan', [AdminSeoController::class, 'scan']);
        Route::delete('seo/scans/{scan}', [AdminSeoController::class, 'discardScan']);

        Route::get('ratings', [AdminRatingController::class, 'index']);
        Route::patch('ratings/{rating}/hide', [AdminRatingController::class, 'hide']);
        Route::patch('ratings/{rating}/unhide', [AdminRatingController::class, 'unhide']);

        Route::get('banners', [AdminBannerController::class, 'index']);
        Route::post('banners', [AdminBannerController::class, 'store']);
        Route::put('banners/{banner}', [AdminBannerController::class, 'update']);
        Route::delete('banners/{banner}', [AdminBannerController::class, 'destroy']);

        Route::get('branding', [AdminBrandingController::class, 'show']);
        // Every admin can see current branding; only a super admin can change
        // it — same tier as payment refunds and role grants.
        Route::post('branding', [AdminBrandingController::class, 'update'])->middleware('super_admin');

        // Open to any admin (not just super admin) — the secret itself is
        // still never echoed back in full (see SecurityController::respond).
        Route::get('security', [AdminSecurityController::class, 'show']);
        Route::post('security', [AdminSecurityController::class, 'update']);

        // Any admin can send themselves a test email — it only ever mails
        // the calling admin's own address, so it needs no extra guard.
        Route::post('mail-test', [MailTestController::class, 'send']);

        Route::get('advertisements', [AdminAdvertisementController::class, 'index']);
        Route::post('advertisements', [AdminAdvertisementController::class, 'store']);
        Route::put('advertisements/{advertisement}', [AdminAdvertisementController::class, 'update']);
        Route::delete('advertisements/{advertisement}', [AdminAdvertisementController::class, 'destroy']);

        Route::get('blog', [AdminBlogPostController::class, 'index']);
        Route::get('blog/{blogPost}', [AdminBlogPostController::class, 'show']);
        Route::post('blog', [AdminBlogPostController::class, 'store']);
        Route::put('blog/{blogPost}', [AdminBlogPostController::class, 'update']);
        Route::delete('blog/{blogPost}', [AdminBlogPostController::class, 'destroy']);

        Route::get('conversations', [AdminConversationController::class, 'index']);
        Route::get('conversations/{conversation}', [AdminConversationController::class, 'show']);
        Route::post('conversations/{conversation}/messages', [AdminConversationController::class, 'sendMessage']);

        Route::prefix('locations')->group(function () {
            Route::post('provinces', [LocationManagementController::class, 'storeProvince']);
            Route::put('provinces/{province}', [LocationManagementController::class, 'updateProvince']);
            Route::delete('provinces/{province}', [LocationManagementController::class, 'destroyProvince']);

            Route::post('districts', [LocationManagementController::class, 'storeDistrict']);
            Route::put('districts/{district}', [LocationManagementController::class, 'updateDistrict']);
            Route::delete('districts/{district}', [LocationManagementController::class, 'destroyDistrict']);

            Route::post('municipalities', [LocationManagementController::class, 'storeMunicipality']);
            Route::put('municipalities/{municipality}', [LocationManagementController::class, 'updateMunicipality']);
            Route::delete('municipalities/{municipality}', [LocationManagementController::class, 'destroyMunicipality']);

            Route::post('wards', [LocationManagementController::class, 'storeWard']);
            Route::delete('wards/{ward}', [LocationManagementController::class, 'destroyWard']);

            Route::post('neighborhoods', [LocationManagementController::class, 'storeNeighborhood']);
            Route::put('neighborhoods/{neighborhood}', [LocationManagementController::class, 'updateNeighborhood']);
            Route::delete('neighborhoods/{neighborhood}', [LocationManagementController::class, 'destroyNeighborhood']);
        });
    });
});
