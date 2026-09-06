import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { MapPin, Search } from 'lucide-react'
import { useMunicipalities } from '../lib/api/locations'
import { BannerCarousel } from '../components/home/BannerCarousel'
import { Card } from '../components/ui/Card'
import { Button } from '../components/ui/Button'
import { Skeleton } from '../components/ui/Skeleton'
import { EmptyState } from '../components/ui/EmptyState'
import { ErrorState } from '../components/ui/ErrorState'

export function Home() {
  const { data: municipalities, isPending, isError, refetch } = useMunicipalities()
  const [query, setQuery] = useState('')
  const navigate = useNavigate()

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    navigate(query.trim() ? `/search?q=${encodeURIComponent(query.trim())}` : '/search')
  }

  return (
    <div className="flex flex-col gap-12">
      <section className="flex flex-col items-center gap-6 rounded-card bg-trust-700 px-6 py-16 text-center text-white">
        <h1 className="max-w-2xl font-display text-3xl font-semibold sm:text-4xl">
          Find, verify, and confidently act on your next property in Nepal
        </h1>
        <p className="max-w-xl text-trust-100">
          Browse verified listings across Kathmandu Valley, Pokhara, Chitwan and Biratnagar —
          with trust scores, land due-diligence, and true cost calculators built in.
        </p>
        <form
          role="search"
          className="flex w-full max-w-2xl flex-col gap-2 rounded-card bg-white p-2 sm:flex-row"
          onSubmit={handleSearch}
        >
          <label htmlFor="home-search" className="sr-only">
            Search by city, municipality, or neighborhood
          </label>
          <div className="flex flex-1 items-center gap-2 px-2">
            <MapPin className="h-5 w-5 shrink-0 text-ink-700/50" aria-hidden="true" />
            <input
              id="home-search"
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search by title or keyword"
              className="h-11 w-full bg-transparent text-sm text-ink-900 placeholder:text-ink-700/50 focus:outline-none"
            />
          </div>
          <Button type="submit" size="lg">
            <Search className="h-4 w-4" /> Search
          </Button>
        </form>
      </section>

      <BannerCarousel />

      <section>
        <h2 className="mb-4 font-display text-2xl font-semibold text-ink-900">
          Browse by city
        </h2>

        {isPending && (
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
            {Array.from({ length: 6 }).map((_, i) => (
              <Skeleton key={i} className="h-24 w-full" />
            ))}
          </div>
        )}

        {isError && <ErrorState onRetry={refetch} description="Couldn't load cities right now." />}

        {!isPending && !isError && municipalities?.length === 0 && (
          <EmptyState title="No cities available yet" description="Check back soon." />
        )}

        {!isPending && !isError && municipalities && municipalities.length > 0 && (
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
            {municipalities.map((m) => (
              <Card
                key={m.id}
                role="button"
                tabIndex={0}
                onClick={() => navigate(`/search?municipality_id=${m.id}`)}
                onKeyDown={(e) => e.key === 'Enter' && navigate(`/search?municipality_id=${m.id}`)}
                className="flex cursor-pointer flex-col items-center gap-2 p-4 text-center transition-shadow hover:shadow-md"
              >
                <MapPin className="h-5 w-5 text-trust-700" aria-hidden="true" />
                <span className="text-sm font-medium text-ink-900">{m.name}</span>
                <span className="text-xs text-ink-700/60">{m.ward_count} wards</span>
              </Card>
            ))}
          </div>
        )}
      </section>
    </div>
  )
}
