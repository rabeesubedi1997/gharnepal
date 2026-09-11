import { Link } from 'react-router-dom'
import { BedDouble, Eye, Heart, Home, MapPin, Ruler, ShowerHead, Sparkles } from 'lucide-react'
import { clsx } from 'clsx'
import { Card } from '../ui/Card'
import { TrustScoreChip } from '../trust/TrustBadge'
import { RatingStars } from './RatingStars'
import { formatCompactCount, formatNprCompact } from '../../design-system/tokens'
import type { ListingSummary } from '../../lib/api/listings'
import { useAddFavorite, useFavorites, useRemoveFavorite } from '../../lib/api/favorites'
import { useCurrentUser } from '../../lib/api/auth'
import { useRequireAuth } from '../auth/AuthGateProvider'

const CLOSED_STATUS_LABEL: Partial<Record<ListingSummary['status'], string>> = {
  sold: 'Sold',
  rented: 'Rented',
}

export function PropertyCard({ listing }: { listing: ListingSummary }) {
  const closedLabel = CLOSED_STATUS_LABEL[listing.status]
  const locationLabel = [
    listing.location?.neighborhood,
    listing.location?.municipality,
    listing.location?.ward_number ? `Ward ${listing.location.ward_number}` : null,
  ]
    .filter(Boolean)
    .join(', ')

  const { data: user } = useCurrentUser()
  const requireAuth = useRequireAuth()
  const { data: favorites } = useFavorites(!!user)
  const addFavorite = useAddFavorite()
  const removeFavorite = useRemoveFavorite()
  const isFavorited = !!favorites?.data.some((f) => f.id === listing.id)

  const toggleFavorite = (e: React.MouseEvent) => {
    // Quick action right from the grid — don't let it also trigger the
    // card's own <Link> navigation into the listing detail page.
    e.preventDefault()
    e.stopPropagation()
    requireAuth(() => (isFavorited ? removeFavorite.mutate(listing.id) : addFavorite.mutate(listing.id)))
  }

  return (
    <Link to={`/listings/${listing.slug}`} className="block">
      <Card className="flex h-full flex-col overflow-hidden transition-shadow hover:shadow-md">
        <div className="relative aspect-[4/3] w-full overflow-hidden bg-stone-100">
          {closedLabel ? (
            <span className="absolute left-2 top-2 z-10 inline-flex items-center rounded-full bg-ink-900/80 px-2 py-0.5 text-xs font-semibold text-white shadow">
              {closedLabel}
            </span>
          ) : (
            listing.is_featured && (
              <span className="absolute left-2 top-2 z-10 inline-flex items-center gap-1 rounded-full bg-accent-600 px-2 py-0.5 text-xs font-semibold text-white shadow">
                <Sparkles className="h-3 w-3" aria-hidden="true" /> Featured
              </span>
            )
          )}
          <button
            type="button"
            onClick={toggleFavorite}
            aria-label={isFavorited ? 'Remove from saved' : 'Save property'}
            className="absolute right-2 top-2 z-10 rounded-full bg-white/90 p-1.5 shadow-sm hover:bg-white"
          >
            <Heart className={clsx('h-4 w-4', isFavorited ? 'fill-accent-600 text-accent-600' : 'text-ink-700')} />
          </button>
          {listing.cover_image_url ? (
            <img
              src={listing.cover_image_url}
              alt={listing.title}
              className={`h-full w-full object-cover ${closedLabel ? 'grayscale-[40%]' : ''}`}
            />
          ) : (
            <div className="flex h-full w-full items-center justify-center text-ink-700/30">
              <Home className="h-10 w-10" aria-hidden="true" />
            </div>
          )}
        </div>
        <div className="flex flex-1 flex-col gap-1.5 p-3">
          <p className="font-semibold text-trust-700">
            {formatNprCompact(listing.price)}
            {listing.purpose === 'rent' && listing.price_period === 'monthly' && (
              <span className="text-xs font-normal text-ink-700/60"> / month</span>
            )}
          </p>
          <div className="flex items-center justify-between gap-2">
            <h3 className="line-clamp-1 text-sm font-medium text-ink-900">{listing.title}</h3>
            {listing.trust_score != null && <TrustScoreChip score={listing.trust_score} />}
          </div>
          {listing.rating.count > 0 && <RatingStars average={listing.rating.average} count={listing.rating.count} />}
          {locationLabel && (
            <p className="flex items-center gap-1 text-xs text-ink-700/60">
              <MapPin className="h-3 w-3 shrink-0" aria-hidden="true" />
              <span className="line-clamp-1">{locationLabel}</span>
            </p>
          )}
          <div className="mt-auto flex gap-3 pt-1 text-xs text-ink-700/70">
            {listing.bedrooms != null && (
              <span className="flex items-center gap-1">
                <BedDouble className="h-3.5 w-3.5" aria-hidden="true" /> {listing.bedrooms}
              </span>
            )}
            {listing.bathrooms != null && (
              <span className="flex items-center gap-1">
                <ShowerHead className="h-3.5 w-3.5" aria-hidden="true" /> {listing.bathrooms}
              </span>
            )}
            {listing.area_sqm != null && (
              <span className="flex items-center gap-1">
                <Ruler className="h-3.5 w-3.5" aria-hidden="true" /> {Math.round(listing.area_sqm)} m²
              </span>
            )}
            {listing.views_count > 0 && (
              <span className="ml-auto flex items-center gap-1 text-ink-700/50">
                <Eye className="h-3.5 w-3.5" aria-hidden="true" /> {formatCompactCount(listing.views_count)}
              </span>
            )}
          </div>
        </div>
      </Card>
    </Link>
  )
}
