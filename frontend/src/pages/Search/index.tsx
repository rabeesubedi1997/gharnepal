import { useEffect, useState } from 'react'
import { useLocation, useSearchParams } from 'react-router-dom'
import { Bookmark, List, Map as MapIcon, SlidersHorizontal } from 'lucide-react'
import { useListingSearch, type SearchFilters } from '../../lib/api/listings'
import { useCreateSavedSearch } from '../../lib/api/savedSearches'
import { useCurrentUser } from '../../lib/api/auth'
import { filtersFromSearchParams, filtersToSearchParams } from '../../lib/searchParams'
import { PropertyCard } from '../../components/property/PropertyCard'
import { MapView } from '../../components/property/MapView'
import { FilterPanel } from './FilterPanel'
import { Button } from '../../components/ui/Button'
import { Modal } from '../../components/ui/Modal'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'

/** Routes like /buy, /rent, /rooms, /land, /commercial preset a filter before the
 * user has touched anything — they still land on the same search experience. */
const ROUTE_PRESETS: Record<string, SearchFilters> = {
  '/buy': { purpose: 'sale' },
  '/rent': { purpose: 'rent' },
  '/rooms': { property_type: 'room' },
  '/land': { property_type: 'land' },
  '/commercial': { property_type: 'commercial' },
}

const TITLES: Record<string, string> = {
  '/buy': 'Properties for sale',
  '/rent': 'Properties for rent',
  '/rooms': 'Rooms for rent',
  '/land': 'Land for sale',
  '/commercial': 'Commercial properties',
  '/search': 'Search results',
}

export function Search() {
  const location = useLocation()
  const [searchParams, setSearchParams] = useSearchParams()
  const preset = ROUTE_PRESETS[location.pathname] ?? {}

  const [filters, setFilters] = useState<SearchFilters>({ ...preset, ...filtersFromSearchParams(searchParams) })
  const [view, setView] = useState<'list' | 'map'>('list')
  const [filtersOpen, setFiltersOpen] = useState(false)
  const [saveOpen, setSaveOpen] = useState(false)

  const { data: user } = useCurrentUser()
  const { data, isPending, isError, refetch, isFetching } = useListingSearch(filters)

  // Keep the URL in sync so searches are shareable/bookmarkable.
  useEffect(() => {
    setSearchParams(filtersToSearchParams(filters), { replace: true })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filters])

  return (
    <div className="flex flex-col gap-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <h1 className="font-display text-2xl font-semibold text-ink-900">
          {TITLES[location.pathname] ?? 'Search results'}
        </h1>
        <div className="flex flex-wrap items-center gap-2">
          {user && (
            <Button variant="outline" size="sm" onClick={() => setSaveOpen(true)}>
              <Bookmark className="h-4 w-4" /> Save search
            </Button>
          )}
          <Button variant="outline" size="sm" className="lg:hidden" onClick={() => setFiltersOpen(true)}>
            <SlidersHorizontal className="h-4 w-4" /> Filters
          </Button>
          <div className="flex shrink-0 overflow-hidden rounded-lg border border-stone-200">
            <button
              type="button"
              onClick={() => setView('list')}
              className={`flex items-center gap-1.5 px-3 py-1.5 text-sm ${view === 'list' ? 'bg-trust-700 text-white' : 'text-ink-700'}`}
            >
              <List className="h-4 w-4" /> List
            </button>
            <button
              type="button"
              onClick={() => setView('map')}
              className={`flex items-center gap-1.5 px-3 py-1.5 text-sm ${view === 'map' ? 'bg-trust-700 text-white' : 'text-ink-700'}`}
            >
              <MapIcon className="h-4 w-4" /> Map
            </button>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-[260px_1fr]">
        <aside className="hidden lg:block">
          <FilterPanel filters={filters} onChange={setFilters} />
        </aside>

        <Modal open={filtersOpen} onClose={() => setFiltersOpen(false)} title="Filters">
          <FilterPanel filters={filters} onChange={setFilters} />
          <Button className="mt-4 w-full" onClick={() => setFiltersOpen(false)}>
            Show results
          </Button>
        </Modal>

        <div>
          {isPending && <PropertyGridSkeleton count={9} />}

          {isError && <ErrorState onRetry={refetch} description="Couldn't load listings right now." />}

          {!isPending && !isError && data?.data.length === 0 && (
            <EmptyState
              title="No properties match your filters"
              description="Try widening your price range or removing a filter."
            />
          )}

          {!isPending && !isError && data && data.data.length > 0 && (
            <>
              <p className="mb-3 text-sm text-ink-700/60">
                {data.meta.total} {data.meta.total === 1 ? 'property' : 'properties'} found
                {isFetching && ' · updating…'}
              </p>
              {view === 'list' ? (
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
                  {data.data.map((listing) => (
                    <PropertyCard key={listing.id} listing={listing} />
                  ))}
                </div>
              ) : (
                <MapView listings={data.data} />
              )}

              {data.meta.last_page > 1 && (
                <div className="mt-6 flex justify-center gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    disabled={(filters.page ?? 1) <= 1}
                    onClick={() => setFilters((f) => ({ ...f, page: (f.page ?? 1) - 1 }))}
                  >
                    Previous
                  </Button>
                  <span className="flex items-center px-2 text-sm text-ink-700/70">
                    Page {data.meta.current_page} of {data.meta.last_page}
                  </span>
                  <Button
                    variant="outline"
                    size="sm"
                    disabled={data.meta.current_page >= data.meta.last_page}
                    onClick={() => setFilters((f) => ({ ...f, page: (f.page ?? 1) + 1 }))}
                  >
                    Next
                  </Button>
                </div>
              )}
            </>
          )}
        </div>
      </div>

      <SaveSearchModal open={saveOpen} onClose={() => setSaveOpen(false)} filters={filters} />
    </div>
  )
}

function SaveSearchModal({ open, onClose, filters }: { open: boolean; onClose: () => void; filters: SearchFilters }) {
  const [name, setName] = useState('')
  const [saved, setSaved] = useState(false)
  const create = useCreateSavedSearch()

  const handleClose = () => {
    setName('')
    setSaved(false)
    onClose()
  }

  return (
    <Modal open={open} onClose={handleClose} title="Save this search">
      {saved ? (
        <div className="flex flex-col items-center gap-3 py-4 text-center">
          <p className="text-sm text-ink-900">Saved! We'll use this to power alerts soon.</p>
          <Button size="sm" onClick={handleClose}>Done</Button>
        </div>
      ) : (
        <div className="flex flex-col gap-3">
          <label className="flex flex-col gap-1.5">
            <span className="text-sm font-medium text-ink-900">Name this search</span>
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. 2BHK rentals in Kathmandu under 30k"
              className="h-10 rounded-lg border border-stone-200 px-3 text-sm focus:outline-none focus:ring-2 focus:ring-trust-700"
            />
          </label>
          <Button
            isLoading={create.isPending}
            disabled={!name.trim()}
            onClick={() => create.mutate({ name: name.trim(), filters }, { onSuccess: () => setSaved(true) })}
          >
            Save search
          </Button>
        </div>
      )}
    </Modal>
  )
}
