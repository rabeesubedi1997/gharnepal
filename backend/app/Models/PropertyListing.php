<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class PropertyListing extends Model
{
    use SoftDeletes;

    public const STATUS_DRAFT = 'draft';
    public const STATUS_PENDING_REVIEW = 'pending_review';
    public const STATUS_PUBLISHED = 'published';
    public const STATUS_PAUSED = 'paused';
    public const STATUS_RENTED = 'rented';
    public const STATUS_SOLD = 'sold';
    public const STATUS_REJECTED = 'rejected';
    public const STATUS_EXPIRED = 'expired';

    protected $fillable = [
        'property_id', 'purpose', 'price', 'price_period', 'currency', 'negotiable',
        'availability_date', 'status', 'title', 'slug', 'description',
        'published_at', 'expires_at', 'featured_until', 'views_count',
        'created_by', 'reviewed_by', 'reviewed_at', 'rejection_reason',
    ];

    protected function casts(): array
    {
        return [
            'price' => 'decimal:2',
            'negotiable' => 'boolean',
            'availability_date' => 'date',
            'published_at' => 'datetime',
            'expires_at' => 'datetime',
            'featured_until' => 'datetime',
            'reviewed_at' => 'datetime',
        ];
    }

    public function property(): BelongsTo
    {
        return $this->belongsTo(Property::class);
    }

    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function reviewedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    public function favorites(): HasMany
    {
        return $this->hasMany(Favorite::class);
    }

    public function reports(): HasMany
    {
        return $this->hasMany(ListingReport::class);
    }

    public function duplicateFlags(): HasMany
    {
        return $this->hasMany(DuplicateListingFlag::class);
    }

    public function conversations(): HasMany
    {
        return $this->hasMany(Conversation::class);
    }

    public function priceHistory(): HasMany
    {
        return $this->hasMany(PriceHistory::class)->orderByDesc('changed_at');
    }

    public function viewingRequests(): HasMany
    {
        return $this->hasMany(ViewingRequest::class);
    }

    public function trustScore(): HasOne
    {
        return $this->hasOne(ListingTrustScore::class);
    }

    public function activeOverride(): HasOne
    {
        return $this->hasOne(TrustScoreOverride::class)->where('active', true);
    }

    public function amenities(): BelongsToMany
    {
        return $this->belongsToMany(Amenity::class, 'listing_amenities');
    }

    public function ratings(): MorphMany
    {
        return $this->morphMany(Rating::class, 'rateable');
    }

    public function isPubliclyVisible(): bool
    {
        return $this->status === self::STATUS_PUBLISHED;
    }

    public function isFeatured(): bool
    {
        return $this->featured_until !== null && $this->featured_until->isFuture();
    }

    /**
     * A short, speakable reference for phone/WhatsApp conversations ("the code is
     * GN-00042") — derived from the id rather than stored, since the id is already
     * a stable, unique, sequential number with nothing else to compute.
     */
    public function referenceCode(): string
    {
        return 'GN-'.str_pad((string) $this->id, 5, '0', STR_PAD_LEFT);
    }
}
