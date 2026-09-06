import { Link } from 'react-router-dom'
import { BedDouble, Home, MapPin, Ruler, ShowerHead, Sparkles } from 'lucide-react'
import { Card } from '../ui/Card'
import { TrustScoreChip } from '../trust/TrustBadge'
import { RatingStars } from './RatingStars'
import { formatNprCompact } from '../../design-system/tokens'
import type { ListingSummary } from '../../lib/api/listings'

export function PropertyCard({ listing }: { listing: ListingSummary }) {
  const locationLabel = [
    listing.location?.neighborhood,
    listing.location?.municipality,
    listing.location?.ward_number ? `Ward ${listing.location.ward_number}` : null,
  ]
    .filter(Boolean)
    .join(', ')

  return (
    <Link to={`/listings/${listing.slug}`} className="block">
      <Card className="flex h-full flex-col overflow-hidden transition-shadow hover:shadow-md">
        <div className="relative aspect-[4/3] w-full overflow-hidden bg-stone-100">
          {listing.is_featured && (
            <span className="absolute left-2 top-2 z-10 inline-flex items-center gap-1 rounded-full bg-accent-600 px-2 py-0.5 text-xs font-semibold text-white shadow">
              <Sparkles className="h-3 w-3" aria-hidden="true" /> Featured
            </span>
          )}
          {listing.cover_image_url ? (
            <img src={listing.cover_image_url} alt={listing.title} className="h-full w-full object-cover" />
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
          </div>
        </div>
      </Card>
    </Link>
  )
}
