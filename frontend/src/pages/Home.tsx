import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import {
  Building2,
  Calculator,
  Download,
  MapPin,
  Search,
  ShieldCheck,
  Smartphone,
  Sparkles,
  Users,
} from 'lucide-react'
import { useMunicipalities } from '../lib/api/locations'
import { useListingSearch } from '../lib/api/listings'
import { usePlatformStats } from '../lib/api/platformStats'
import { useStaticPageSeo } from '../lib/api/seo'
import { useInstallPrompt } from '../lib/useInstallPrompt'
import { filtersToSearchParams } from '../lib/searchParams'
import { SeoHead } from '../components/seo/SeoHead'
import { BannerCarousel } from '../components/home/BannerCarousel'
import { HeroBackdrop } from '../components/home/HeroBackdrop'
import { PropertyCard } from '../components/property/PropertyCard'
import { AdSlot } from '../components/marketing/AdSlot'
import { Card } from '../components/ui/Card'
import { Button } from '../components/ui/Button'
import { Skeleton } from '../components/ui/Skeleton'
import { PropertyGridSkeleton } from '../components/ui/Skeleton'
import { EmptyState } from '../components/ui/EmptyState'
import { ErrorState } from '../components/ui/ErrorState'

type HeroTab = 'buy' | 'rent' | 'commercial' | 'land'

const HERO_TABS: { key: HeroTab; label: string }[] = [
  { key: 'buy', label: 'For Sale' },
  { key: 'rent', label: 'For Rent' },
  { key: 'commercial', label: 'Commercial' },
  { key: 'land', label: 'Land / Plots' },
]

// (min_price, max_price) in plain NPR — matches formatNprCompact's own
// Lakh/Crore bands so the labels below read naturally for this market.
const BUDGET_BANDS: { label: string; min?: number; max?: number }[] = [
  { label: 'Any budget' },
  { label: 'Under Rs 50 Lakh', max: 5_000_000 },
  { label: 'Rs 50 Lakh – 1 Crore', min: 5_000_000, max: 10_000_000 },
  { label: 'Rs 1 – 2 Crore', min: 10_000_000, max: 20_000_000 },
  { label: 'Rs 2 Crore+', min: 20_000_000 },
]

const FEATURE_CHIPS = [
  { to: '/search', icon: ShieldCheck, label: 'Explainable trust scores' },
  { to: '/calculators/rental', icon: Calculator, label: 'True cost calculator' },
  { to: '/neighborhoods', icon: Sparkles, label: 'Neighborhood insights' },
]

export function Home() {
  const { data: municipalities, isPending, isError, refetch } = useMunicipalities()
  const { data: seo } = useStaticPageSeo('home')
  const navigate = useNavigate()

  const [heroTab, setHeroTab] = useState<HeroTab>('buy')
  const [cityId, setCityId] = useState('')
  const [budgetIndex, setBudgetIndex] = useState(0)

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    const band = BUDGET_BANDS[budgetIndex]
    const params = filtersToSearchParams({
      ...(heroTab === 'buy' && { purpose: 'sale' }),
      ...(heroTab === 'rent' && { purpose: 'rent' }),
      ...(heroTab === 'commercial' && { property_type: 'commercial' }),
      ...(heroTab === 'land' && { property_type: 'land' }),
      ...(cityId && { municipality_id: Number(cityId) }),
      ...(band.min && { min_price: band.min }),
      ...(band.max && { max_price: band.max }),
    })
    navigate(`/search?${params.toString()}`)
  }

  return (
    <div className="flex flex-col gap-16">
      <SeoHead seo={seo} />

      {/* Hero */}
      <section className="relative -mx-4 overflow-hidden px-4 py-16 sm:-mx-6 sm:px-6 sm:py-24 lg:-mx-10 lg:px-10">
        <HeroBackdrop />
        <div className="relative mx-auto flex max-w-3xl flex-col items-center gap-6 text-center">
          <span className="inline-flex items-center gap-1.5 rounded-full bg-white/10 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-white backdrop-blur-sm">
            Nepal's verified property marketplace
          </span>
          <h1 className="font-display text-3xl font-extrabold leading-tight text-white sm:text-5xl">
            Find your sanctuary <span className="text-accent-500">in Nepal</span>
          </h1>
          <p className="max-w-xl text-base text-white/80">
            Browse verified listings across Kathmandu Valley, Pokhara, Chitwan and Biratnagar —
            with trust scores, land due-diligence, and true cost calculators built in.
          </p>

          <form
            role="search"
            className="w-full max-w-2xl rounded-2xl bg-white/95 p-3 shadow-xl shadow-black/20 backdrop-blur"
            onSubmit={handleSearch}
          >
            <div className="mb-3 flex flex-wrap gap-1.5">
              {HERO_TABS.map((tab) => (
                <button
                  key={tab.key}
                  type="button"
                  onClick={() => setHeroTab(tab.key)}
                  className={
                    heroTab === tab.key
                      ? 'rounded-lg bg-trust-700 px-3 py-1.5 text-xs font-semibold text-white'
                      : 'rounded-lg px-3 py-1.5 text-xs font-medium text-ink-700 hover:bg-stone-100'
                  }
                >
                  {tab.label}
                </button>
              ))}
            </div>
            <div className="flex flex-col gap-2 sm:flex-row">
              <div className="flex flex-1 items-center gap-2 rounded-lg border border-stone-200 px-3">
                <MapPin className="h-4 w-4 shrink-0 text-ink-700/50" aria-hidden="true" />
                <select
                  aria-label="City or neighborhood"
                  value={cityId}
                  onChange={(e) => setCityId(e.target.value)}
                  className="h-11 w-full min-w-0 bg-transparent text-sm text-ink-900 focus:outline-none"
                >
                  <option value="">Kathmandu Valley (All)</option>
                  {municipalities?.map((m) => (
                    <option key={m.id} value={m.id}>
                      {m.name}
                    </option>
                  ))}
                </select>
              </div>
              <div className="flex flex-1 items-center gap-2 rounded-lg border border-stone-200 px-3">
                <select
                  aria-label="Budget"
                  value={budgetIndex}
                  onChange={(e) => setBudgetIndex(Number(e.target.value))}
                  className="h-11 w-full min-w-0 bg-transparent text-sm text-ink-900 focus:outline-none"
                >
                  {BUDGET_BANDS.map((band, i) => (
                    <option key={band.label} value={i}>
                      {band.label}
                    </option>
                  ))}
                </select>
              </div>
              <Button type="submit" size="lg" className="sm:w-auto">
                <Search className="h-4 w-4" /> Search Properties
              </Button>
            </div>
          </form>

          <div className="flex flex-wrap items-center justify-center gap-2">
            {FEATURE_CHIPS.map(({ to, icon: Icon, label }) => (
              <Link
                key={to}
                to={to}
                className="inline-flex items-center gap-1.5 rounded-full border border-white/20 bg-white/10 px-3 py-1.5 text-xs font-medium text-white backdrop-blur-sm transition-colors hover:bg-white/20"
              >
                <Icon className="h-3.5 w-3.5" aria-hidden="true" /> {label}
              </Link>
            ))}
          </div>
        </div>
      </section>

      <BannerCarousel />

      <FeaturedListings />

      {/* Explore by region/valley */}
      <section>
        <h2 className="mb-1 font-display text-2xl font-semibold text-ink-900">
          Explore Nepal by Region &amp; Valley
        </h2>
        <p className="mb-4 text-sm text-ink-700/70">
          Neighborhood prices, school catchments, and infrastructure growth corridors.
        </p>

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
            {municipalities.map((m) =>
              m.image_url ? (
                <Card
                  key={m.id}
                  role="button"
                  tabIndex={0}
                  onClick={() => navigate(`/search?municipality_id=${m.id}`)}
                  onKeyDown={(e) => e.key === 'Enter' && navigate(`/search?municipality_id=${m.id}`)}
                  className="group relative aspect-[4/5] cursor-pointer overflow-hidden p-0 transition-all hover:-translate-y-0.5 hover:shadow-md"
                >
                  <img
                    src={m.image_url}
                    alt=""
                    className="h-full w-full object-cover transition-transform duration-500 ease-out group-hover:scale-110"
                  />
                  <div className="absolute inset-0 flex flex-col justify-end gap-0.5 bg-gradient-to-t from-ink-900/80 via-ink-900/10 to-transparent p-3">
                    <span className="text-sm font-semibold text-white">{m.name}</span>
                    <span className="text-xs text-white/80">{m.ward_count} wards</span>
                  </div>
                </Card>
              ) : (
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
              ),
            )}
          </div>
        )}
      </section>

      <TrustStrip />

      <InstallAppSection />

      <AdSlot placement="home_before_footer" aspectClassName="aspect-[21/9] sm:aspect-[4/1]" />
    </div>
  )
}

function FeaturedListings() {
  const { data, isPending, isError, refetch } = useListingSearch({ sort: 'newest' })
  const listings = data?.data.slice(0, 6) ?? []

  if (isPending) return <PropertyGridSkeleton count={6} />
  if (isError) return <ErrorState onRetry={refetch} description="Couldn't load listings right now." />
  if (listings.length === 0) return null

  return (
    <section>
      <div className="mb-4 flex items-end justify-between gap-3">
        <div>
          <h2 className="font-display text-2xl font-semibold text-ink-900">Featured &amp; Verified Listings</h2>
          <p className="text-sm text-ink-700/70">Authentic land ownership documents, and clear title deed histories.</p>
        </div>
        <Link to="/search" className="shrink-0 text-sm font-medium text-trust-700 hover:underline">
          View all listings →
        </Link>
      </div>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {listings.map((listing) => (
          <PropertyCard key={listing.id} listing={listing} />
        ))}
      </div>
    </section>
  )
}

function TrustStrip() {
  const { data: stats } = usePlatformStats()

  const tiles = [
    { icon: Building2, label: 'Published listings', value: stats?.published_listings },
    { icon: ShieldCheck, label: 'Verified agencies', value: stats?.verified_agencies },
    { icon: Users, label: 'Phone-verified owners', value: stats ? `${stats.phone_verified_owner_pct}%` : undefined },
    { icon: MapPin, label: 'Cities covered', value: stats?.cities_covered },
  ]

  return (
    <section className="rounded-card border border-stone-200 bg-white p-6 sm:p-8">
      <div className="mb-6 max-w-2xl">
        <h2 className="font-display text-2xl font-semibold text-ink-900">Built for Transparency</h2>
        <p className="mt-1 text-sm text-ink-700/70">
          Every figure below is a live count from listings and accounts on this platform right now — not a marketing estimate.
        </p>
      </div>
      <div className="grid grid-cols-2 gap-6 sm:grid-cols-4">
        {tiles.map(({ icon: Icon, label, value }) => (
          <div key={label} className="flex flex-col gap-2">
            <span className="flex h-9 w-9 items-center justify-center rounded-lg bg-trust-100 text-trust-700">
              <Icon className="h-4 w-4" aria-hidden="true" />
            </span>
            <span className="font-display text-2xl font-bold text-ink-900">{value ?? <Skeleton className="h-7 w-12" />}</span>
            <span className="text-xs text-ink-700/60">{label}</span>
          </div>
        ))}
      </div>
    </section>
  )
}

function InstallAppSection() {
  const { canInstall, promptInstall } = useInstallPrompt()

  return (
    <section className="flex flex-col items-center gap-4 rounded-card bg-trust-700 p-8 text-center sm:p-12">
      <span className="flex h-12 w-12 items-center justify-center rounded-full bg-white/15 text-white">
        <Smartphone className="h-6 w-6" aria-hidden="true" />
      </span>
      <h2 className="max-w-md font-display text-2xl font-bold text-white sm:text-3xl">
        Take Ghar Nepal wherever you go
      </h2>
      <p className="max-w-md text-sm text-white/80">
        Install it like an app — get browser notifications the moment a matching listing appears, and browse
        even with a patchy connection.
      </p>
      {canInstall ? (
        <Button variant="secondary" size="lg" onClick={() => promptInstall()}>
          <Download className="h-4 w-4" /> Install Ghar Nepal
        </Button>
      ) : (
        <p className="max-w-sm text-xs text-white/60">
          On iPhone/iPad: open the Share menu in Safari and choose "Add to Home Screen". On desktop Chrome/Edge,
          look for the install icon in the address bar.
        </p>
      )}
    </section>
  )
}
