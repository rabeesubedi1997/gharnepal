import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { Calculator, MapPin, Search, ShieldCheck, Sparkles } from 'lucide-react'
import { useMunicipalities } from '../lib/api/locations'
import { useStaticPageSeo } from '../lib/api/seo'
import { SeoHead } from '../components/seo/SeoHead'
import { BannerCarousel } from '../components/home/BannerCarousel'
import { HeroBackdrop } from '../components/home/HeroBackdrop'
import { Card } from '../components/ui/Card'
import { Button } from '../components/ui/Button'
import { Skeleton } from '../components/ui/Skeleton'
import { EmptyState } from '../components/ui/EmptyState'
import { ErrorState } from '../components/ui/ErrorState'

const FEATURE_CHIPS = [
  { to: '/search', icon: ShieldCheck, label: 'Explainable trust scores' },
  { to: '/calculators/rental', icon: Calculator, label: 'True cost calculator' },
  { to: '/neighborhoods', icon: Sparkles, label: 'Neighborhood insights' },
]

export function Home() {
  const { data: municipalities, isPending, isError, refetch } = useMunicipalities()
  const { data: seo } = useStaticPageSeo('home')
  const [query, setQuery] = useState('')
  const navigate = useNavigate()

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    navigate(query.trim() ? `/search?q=${encodeURIComponent(query.trim())}` : '/search')
  }

  return (
    <div className="flex flex-col gap-12">
      <SeoHead seo={seo} />
      <section className="relative overflow-hidden rounded-card border border-stone-200 bg-white px-6 py-14 sm:py-20">
        <HeroBackdrop />
        <div className="relative flex flex-col items-center gap-6 text-center">
          <span className="inline-flex items-center gap-1.5 rounded-full bg-trust-100 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-trust-700">
            Nepal's verified property marketplace
          </span>
          <h1 className="max-w-2xl font-display text-3xl font-extrabold leading-tight text-ink-900 sm:text-5xl">
            Find, verify, and <span className="text-trust-700">confidently act</span> on your next property
          </h1>
          <p className="max-w-xl text-base text-ink-700/80">
            Browse verified listings across Kathmandu Valley, Pokhara, Chitwan and Biratnagar —
            with trust scores, land due-diligence, and true cost calculators built in.
          </p>
          <form
            role="search"
            className="flex w-full max-w-2xl flex-col gap-2 rounded-xl border border-stone-200 bg-white p-2 shadow-lg shadow-ink-900/5 sm:flex-row"
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
          <div className="flex flex-wrap items-center justify-center gap-2">
            {FEATURE_CHIPS.map(({ to, icon: Icon, label }) => (
              <Link
                key={to}
                to={to}
                className="inline-flex items-center gap-1.5 rounded-full border border-stone-200 bg-stone-50 px-3 py-1.5 text-xs font-medium text-ink-700 transition-colors hover:border-trust-700/30 hover:bg-trust-100 hover:text-trust-700"
              >
                <Icon className="h-3.5 w-3.5" aria-hidden="true" /> {label}
              </Link>
            ))}
          </div>
        </div>
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
                className="flex cursor-pointer flex-col items-center gap-2 p-4 text-center transition-all hover:-translate-y-0.5 hover:border-trust-700/30 hover:shadow-md"
              >
                <span className="flex h-10 w-10 items-center justify-center rounded-full bg-trust-100 text-trust-700">
                  <MapPin className="h-5 w-5" aria-hidden="true" />
                </span>
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
