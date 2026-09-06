import { useState } from 'react'
import { BarChart3, Bookmark, Calculator, CalendarCheck, Plus, ShieldCheck, Sparkles, Trash2 } from 'lucide-react'
import { FeatureListingModal } from '../components/payments/FeatureListingModal'
import { useCurrentUser } from '../lib/api/auth'
import { useOwnerProperties, useTransitionListing, type ListingStatus } from '../lib/api/listings'
import { useDeleteSavedSearch, useSavedSearches } from '../lib/api/savedSearches'
import { useDeleteScenario, useSavedScenarios } from '../lib/api/calculators'
import { useListingAnalytics } from '../lib/api/analytics'
import { filtersToSearchParams } from '../lib/searchParams'
import { formatNpr } from '../design-system/tokens'
import { Card } from '../components/ui/Card'
import { Badge } from '../components/ui/Badge'
import { Button, ButtonLink } from '../components/ui/Button'
import { EmptyState } from '../components/ui/EmptyState'
import { ErrorState } from '../components/ui/ErrorState'
import { PropertyGridSkeleton, Skeleton } from '../components/ui/Skeleton'

const STATUS_TONE: Record<ListingStatus, 'neutral' | 'warning' | 'success' | 'danger' | 'trust'> = {
  draft: 'neutral',
  pending_review: 'warning',
  published: 'success',
  paused: 'neutral',
  rented: 'trust',
  sold: 'trust',
  rejected: 'danger',
  expired: 'neutral',
}

const NEXT_ACTIONS: Partial<Record<ListingStatus, { action: string; label: string }[]>> = {
  draft: [{ action: 'submit', label: 'Submit for review' }],
  published: [{ action: 'pause', label: 'Pause' }, { action: 'mark_rented', label: 'Mark rented' }, { action: 'mark_sold', label: 'Mark sold' }],
  paused: [{ action: 'resume', label: 'Resume' }],
  pending_review: [{ action: 'withdraw', label: 'Withdraw to draft' }],
}

export function Dashboard() {
  const { data: user } = useCurrentUser()
  const { data, isPending, isError, refetch } = useOwnerProperties()
  const transition = useTransitionListing()
  const isAdmin = user?.roles.includes('admin')

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="font-display text-2xl font-semibold text-ink-900">Dashboard</h1>
        <ButtonLink to="/post-property">
          <Plus className="h-4 w-4" /> Post property
        </ButtonLink>
      </div>

      {isAdmin && (
        <Card className="flex flex-wrap items-center justify-between gap-3 border-accent-100 bg-accent-100/40 p-4">
          <div className="flex items-center gap-2 text-sm text-ink-900">
            <ShieldCheck className="h-5 w-5 text-accent-600" aria-hidden="true" />
            You have admin access.
          </div>
          <ButtonLink to="/admin/dashboard" variant="outline" size="sm">
            Open admin console
          </ButtonLink>
        </Card>
      )}

      <div className="flex flex-wrap gap-3">
        <ButtonLink to="/saved" variant="outline" size="sm">Saved properties</ButtonLink>
        <ButtonLink to="/messages" variant="outline" size="sm">Messages</ButtonLink>
        <ButtonLink to="/account/viewing-requests" variant="outline" size="sm">
          <CalendarCheck className="h-4 w-4" /> Viewing requests
        </ButtonLink>
        <ButtonLink to="/account/verification" variant="outline" size="sm">
          <ShieldCheck className="h-4 w-4" /> Verification center
        </ButtonLink>
        <ButtonLink to="/account/match-results" variant="outline" size="sm">
          <Sparkles className="h-4 w-4" /> Smart matches
        </ButtonLink>
        <ButtonLink to="/account/payments" variant="outline" size="sm">
          Payment history
        </ButtonLink>
      </div>

      <SavedSearchesSection />
      <SavedScenariosSection />

      <div>
        <h2 className="mb-3 font-display text-lg font-semibold text-ink-900">My properties</h2>

        {isPending && <PropertyGridSkeleton count={3} />}
        {isError && <ErrorState onRetry={refetch} />}

        {!isPending && !isError && data?.data.length === 0 && (
          <EmptyState
            title="You haven't posted a property yet"
            description="List a room, flat, house, land, or commercial space in a few minutes."
            action={<ButtonLink to="/post-property" size="sm">Post your first property</ButtonLink>}
          />
        )}

        <div className="flex flex-col gap-4">
          {data?.data.map((property) => (
            <Card key={property.id} className="p-4">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <p className="font-medium text-ink-900">
                  {property.property_type.charAt(0).toUpperCase() + property.property_type.slice(1)}
                  {property.address?.municipality && ` · ${property.address.municipality.name}`}
                </p>
              </div>
              {property.listings.length === 0 ? (
                <p className="mt-2 text-sm text-ink-700/60">No listing created for this property yet.</p>
              ) : (
                <ul className="mt-3 flex flex-col gap-2">
                  {property.listings.map((listing) => (
                    <ListingRow key={listing.id} listing={listing} transition={transition} />
                  ))}
                </ul>
              )}
            </Card>
          ))}
        </div>
      </div>
    </div>
  )
}

interface ListingRowProps {
  listing: {
    id: number
    slug: string
    title: string
    status: ListingStatus
    purpose: 'sale' | 'rent'
    price: number
    is_featured: boolean
    featured_until: string | null
  }
  transition: ReturnType<typeof useTransitionListing>
}

function ListingRow({ listing, transition }: ListingRowProps) {
  const [showAnalytics, setShowAnalytics] = useState(false)
  const [featureOpen, setFeatureOpen] = useState(false)
  const { data: analytics, isPending } = useListingAnalytics(listing.id, showAnalytics)

  return (
    <li className="rounded-lg border border-stone-200 p-3">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div>
          <p className="text-sm font-medium text-ink-900">{listing.title}</p>
          <p className="text-xs text-ink-700/60">{formatNpr(listing.price)}</p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <Badge tone={STATUS_TONE[listing.status]}>{listing.status.replace('_', ' ')}</Badge>
          {listing.is_featured ? (
            <Badge tone="accent">
              <Sparkles className="h-3 w-3" /> Featured
              {listing.featured_until && ` until ${new Date(listing.featured_until).toLocaleDateString()}`}
            </Badge>
          ) : (
            listing.status === 'published' && (
              <Button size="sm" variant="outline" onClick={() => setFeatureOpen(true)}>
                <Sparkles className="h-4 w-4" /> Feature
              </Button>
            )
          )}
          {listing.is_featured && listing.status === 'published' && (
            <Button size="sm" variant="ghost" onClick={() => setFeatureOpen(true)}>
              Extend
            </Button>
          )}
          <Button size="sm" variant="ghost" onClick={() => setShowAnalytics((v) => !v)}>
            <BarChart3 className="h-4 w-4" /> {showAnalytics ? 'Hide stats' : 'View stats'}
          </Button>
          {NEXT_ACTIONS[listing.status]?.map(({ action, label }) => (
            <Button
              key={action}
              size="sm"
              variant="outline"
              isLoading={transition.isPending && transition.variables?.listingId === listing.id}
              onClick={() => transition.mutate({ listingId: listing.id, action })}
            >
              {label}
            </Button>
          ))}
        </div>
      </div>
      {showAnalytics && (
        <div className="mt-3 border-t border-stone-100 pt-3">
          {isPending ? (
            <Skeleton className="h-10 w-full" />
          ) : analytics ? (
            <div className="grid grid-cols-2 gap-3 text-center sm:grid-cols-4">
              <Stat label="Views" value={analytics.views_count} />
              <Stat label="Saved" value={analytics.favorites_count} />
              <Stat label="Inquiries" value={analytics.inquiries_count} />
              <Stat label="Viewing requests" value={analytics.viewing_requests_count} />
            </div>
          ) : null}
        </div>
      )}
      <FeatureListingModal open={featureOpen} onClose={() => setFeatureOpen(false)} listingId={listing.id} listingTitle={listing.title} />
    </li>
  )
}

function Stat({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-lg bg-stone-100 p-2">
      <p className="text-lg font-semibold text-ink-900">{value}</p>
      <p className="text-xs text-ink-700/60">{label}</p>
    </div>
  )
}

function SavedSearchesSection() {
  const { data: searches, isPending } = useSavedSearches()
  const remove = useDeleteSavedSearch()

  if (isPending || !searches?.length) return null

  return (
    <div>
      <h2 className="mb-3 flex items-center gap-2 font-display text-lg font-semibold text-ink-900">
        <Bookmark className="h-4 w-4" /> Saved searches
      </h2>
      <div className="flex flex-col gap-2">
        {searches.map((s) => (
          <Card key={s.id} className="flex items-center justify-between gap-3 p-3">
            <ButtonLink
              to={{ pathname: '/search', search: filtersToSearchParams(s.filters).toString() }}
              variant="ghost"
              size="sm"
              className="text-left"
            >
              {s.name}
            </ButtonLink>
            <button
              type="button"
              onClick={() => remove.mutate(s.id)}
              aria-label="Delete saved search"
              className="rounded-md p-1.5 text-ink-700/60 hover:bg-stone-100 hover:text-danger-600"
            >
              <Trash2 className="h-4 w-4" />
            </button>
          </Card>
        ))}
      </div>
    </div>
  )
}

function SavedScenariosSection() {
  const { data: scenarios, isPending } = useSavedScenarios()
  const remove = useDeleteScenario()

  if (isPending || !scenarios?.length) return null

  return (
    <div>
      <h2 className="mb-3 flex items-center gap-2 font-display text-lg font-semibold text-ink-900">
        <Calculator className="h-4 w-4" /> Saved cost estimates
      </h2>
      <div className="flex flex-col gap-2">
        {scenarios.map((s) => (
          <Card key={s.id} className="flex items-center justify-between gap-3 p-3">
            <ButtonLink
              to={s.type === 'rental' ? '/calculators/rental' : '/calculators/purchase'}
              variant="ghost"
              size="sm"
              className="text-left"
            >
              {s.name || (s.type === 'rental' ? 'Rental estimate' : 'Purchase estimate')}
            </ButtonLink>
            <button
              type="button"
              onClick={() => remove.mutate(s.id)}
              aria-label="Delete saved scenario"
              className="rounded-md p-1.5 text-ink-700/60 hover:bg-stone-100 hover:text-danger-600"
            >
              <Trash2 className="h-4 w-4" />
            </button>
          </Card>
        ))}
      </div>
    </div>
  )
}
