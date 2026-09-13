import { useParams } from 'react-router-dom'
import { Folder } from 'lucide-react'
import { useSharedCollection } from '../lib/api/favoriteCollections'
import { PropertyCard } from '../components/property/PropertyCard'
import { PropertyGridSkeleton } from '../components/ui/Skeleton'
import { EmptyState } from '../components/ui/EmptyState'
import { ErrorState } from '../components/ui/ErrorState'
import { ButtonLink } from '../components/ui/Button'

export function SharedCollection() {
  const { token } = useParams<{ token: string }>()
  const { data, isPending, isError, refetch } = useSharedCollection(token)

  if (isPending) {
    return (
      <div className="flex flex-col gap-4">
        <div className="h-8 w-64 animate-pulse rounded bg-stone-200" />
        <PropertyGridSkeleton count={6} />
      </div>
    )
  }

  if (isError || !data) {
    return (
      <ErrorState
        title="This collection doesn't exist"
        description="The link may be mistyped, or the person who shared it has since deleted it."
        onRetry={refetch}
      />
    )
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center gap-2">
        <Folder className="h-6 w-6 text-trust-700" aria-hidden="true" />
        <div>
          <h1 className="font-display text-2xl font-semibold text-ink-900">{data.collection.name}</h1>
          <p className="text-sm text-ink-700/60">Shared by {data.collection.curated_by}</p>
        </div>
      </div>

      {data.data.length === 0 ? (
        <EmptyState
          icon={<Folder className="h-10 w-10" aria-hidden="true" />}
          title="Nothing here yet"
          description="Whoever shared this link hasn't added any listings to it — or the ones they added are no longer live."
          action={<ButtonLink to="/search" size="sm">Browse properties</ButtonLink>}
        />
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {data.data.map((listing) => (
            <PropertyCard key={listing.id} listing={listing} />
          ))}
        </div>
      )}
    </div>
  )
}
