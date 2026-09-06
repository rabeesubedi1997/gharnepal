import { Heart } from 'lucide-react'
import { useFavorites, useRemoveFavorite } from '../lib/api/favorites'
import { PropertyCard } from '../components/property/PropertyCard'
import { PropertyGridSkeleton } from '../components/ui/Skeleton'
import { EmptyState } from '../components/ui/EmptyState'
import { ErrorState } from '../components/ui/ErrorState'
import { ButtonLink } from '../components/ui/Button'

export function Saved() {
  const { data, isPending, isError, refetch } = useFavorites()
  const remove = useRemoveFavorite()

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
          {data.data.map((listing) => (
            <div key={listing.id} className="relative">
              <PropertyCard listing={listing} />
              <button
                type="button"
                onClick={() => remove.mutate(listing.id)}
                aria-label="Remove from saved"
                className="absolute right-2 top-2 rounded-full bg-white/90 p-1.5 shadow-sm hover:bg-white"
              >
                <Heart className="h-4 w-4 fill-accent-600 text-accent-600" />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
