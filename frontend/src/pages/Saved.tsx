import { Heart } from 'lucide-react'
import { useFavorites } from '../lib/api/favorites'
import { PropertyCard } from '../components/property/PropertyCard'
import { PropertyGridSkeleton } from '../components/ui/Skeleton'
import { EmptyState } from '../components/ui/EmptyState'
import { ErrorState } from '../components/ui/ErrorState'
import { ButtonLink } from '../components/ui/Button'

export function Saved() {
  const { data, isPending, isError, refetch } = useFavorites()

  return (
    <div className="flex flex-col gap-6">
      <h1 className="font-display text-2xl font-semibold text-ink-900">Saved properties</h1>

      {isPending && <PropertyGridSkeleton count={6} />}
      {isError && <ErrorState onRetry={refetch} />}

      {!isPending && !isError && data?.data.length === 0 && (
        <EmptyState
          icon={<Heart className="h-10 w-10" aria-hidden="true" />}
          title="No saved properties yet"
          description="Tap the heart icon on any listing to save it here for later."
          action={<ButtonLink to="/search" size="sm">Browse properties</ButtonLink>}
        />
      )}

      {!isPending && !isError && data && data.data.length > 0 && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {/* PropertyCard's own heart toggle (top-right on every card) already
              handles removing from saved — tapping it again unfavorites. */}
          {data.data.map((listing) => (
            <PropertyCard key={listing.id} listing={listing} />
          ))}
        </div>
      )}
    </div>
  )
}
