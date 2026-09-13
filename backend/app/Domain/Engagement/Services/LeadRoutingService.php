<?php

namespace App\Domain\Engagement\Services;

use App\Models\User;
use Illuminate\Database\Eloquent\Collection;

/**
 * A "lead" — a first-contact message or a new viewing request — is exactly
 * the moment a solo agent losing it to a missed notification actually costs
 * a deal. If the listing's owner belongs to a verified, active agency, the
 * lead reaches every member of that agency, not just whichever one person
 * happens to be the property's `created_by` — the same idea as a shared
 * team inbox, kept intentionally simple (no per-agent assignment/rotation).
 * An individual, non-agency owner sees no change at all: they're still the
 * only recipient.
 */
class LeadRoutingService
{
    /** @return Collection<int, User> */
    public function recipientsFor(User $host): Collection
    {
        $agency = $host->agencies()->get()
            ->first(fn ($a) => $a->status === 'active' && $a->isVerified());

        if (! $agency) {
            return new Collection([$host]);
        }

        $members = $agency->members()->get();

        // Defensive: an agency record with no (or only inactive) members
        // shouldn't swallow the lead entirely — fall back to the host.
        return $members->isNotEmpty() ? $members : new Collection([$host]);
    }
}
