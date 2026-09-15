import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import {
  Building2,
  Download,
  MapPin,
  Search,
  ShieldCheck,
  Smartphone,
  Users,
} from 'lucide-react'
import { useMunicipalities } from '../lib/api/locations'
import { useListingSearch, type SearchFilters } from '../lib/api/listings'
import { useNeighborhoodList } from '../lib/api/neighborhoods'
import { usePlatformStats } from '../lib/api/platformStats'
import { useStaticPageSeo } from '../lib/api/seo'
import { useInstallPrompt } from '../lib/useInstallPrompt'
import { useUnitSystem } from '../lib/useUnitSystem'
import { filtersToSearchParams } from '../lib/searchParams'
import { formatCompactCount, formatNprCompact } from '../design-system/tokens'
import { SeoHead } from '../components/seo/SeoHead'
import { BannerCarousel } from '../components/home/BannerCarousel'
import { HeroBackdrop } from '../components/home/HeroBackdrop'
import { AlertSignupBanner } from '../components/home/AlertSignupBanner'
import { PropertyCard } from '../components/property/PropertyCard'
import { AdSlot } from '../components/marketing/AdSlot'
import { Card } from '../components/ui/Card'
import { Button } from '../components/ui/Button'
import { Skeleton } from '../components/ui/Skeleton'
import { PropertyGridSkeleton } from '../components/ui/Skeleton'
import { EmptyState } from '../components/ui/EmptyState'
import { ErrorState } from '../components/ui/ErrorState'

type HeroTab = 'buy' | 'rent' | 'commercial' | 'land'

const HERO_TABS: { key: HeroTab; label: string; label_ne: string }[] = [
  { key: 'buy', label: 'For Sale', label_ne: 'बिक्री' },
  { key: 'rent', label: 'For Rent', label_ne: 'भाडा' },
  { key: 'commercial', label: 'Commercial', label_ne: 'व्यापारिक' },
  { key: 'land', label: 'Land / Plots', label_ne: 'जग्गा' },
]

const PROPERTY_SUBTYPES: { value: string; label: string }[] = [
  { value: '', label: 'Any subtype' },
  { value: 'house', label: 'House / Bungalow' },
  { value: 'apartment', label: 'Apartment' },
  { value: 'room', label: 'Room' },
  { value: 'land', label: 'Land / Plot' },
  { value: 'commercial', label: 'Commercial' },
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


export function Home() {
  const { data: municipalities, isPending, isError, refetch } = useMunicipalities()
  const { data: neighborhoods } = useNeighborhoodList()
  const { data: platformStats } = usePlatformStats()
  const { data: seo } = useStaticPageSeo('home')
  const { unitSystem, setUnitSystem } = useUnitSystem()
  const navigate = useNavigate()

  const [heroTab, setHeroTab] = useState<HeroTab>('buy')
  const [cityId, setCityId] = useState('')
  const [subtype, setSubtype] = useState('')
  const [budgetIndex, setBudgetIndex] = useState(0)

  // Real top-listing-count neighborhoods, not invented "hotspot" copy —
  // renders nothing until there's at least one neighborhood with a
  // published listing, rather than padding the row with empty places.
  const hotspots = [...(neighborhoods ?? [])]
    .filter((n) => n.active_listings_count > 0)
    .sort((a, b) => b.active_listings_count - a.active_listings_count)
    .slice(0, 5)

  // Shared with FeaturedListings below so the "preview" of results sitting
  // right under the hero form always matches what it's currently set to —
  // picking a city here used to only take effect once you pressed Search,
  // so the very next thing on the page (Featured & Verified Listings) kept
  // showing every city, unfiltered, looking exactly like a second, broken
  // search right below the first one.
  const heroFilters: SearchFilters = {
    ...(heroTab === 'buy' && { purpose: 'sale' }),
    ...(heroTab === 'rent' && { purpose: 'rent' }),
    ...(!subtype && heroTab === 'commercial' && { property_type: 'commercial' }),
    ...(!subtype && heroTab === 'land' && { property_type: 'land' }),
    ...(subtype && { property_type: subtype as 'house' | 'apartment' | 'room' | 'land' | 'commercial' }),
    ...(cityId && { municipality_id: Number(cityId) }),
  }
  const heroCityName = cityId ? municipalities?.find((m) => m.id === Number(cityId))?.name : undefined

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    const band = BUDGET_BANDS[budgetIndex]
    const params = filtersToSearchParams({
      ...heroFilters,
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
            Official Nepal Real Estate MLS
          </span>
          <h1 className="font-display text-3xl font-extrabold leading-tight text-white sm:text-5xl">
            Find Your Sanctuary in Nepal
          </h1>
          <p lang="ne" className="max-w-xl font-display text-lg text-white/90">
            नेपालमा तपाईंको सपनाको घर खोज्नुहोस्
          </p>
          <p className="max-w-xl text-base text-white/80">
            Discover vetted freehold residences, agricultural parcels, and prime commercial
            developments with verified Lalpurja (land title) records.
          </p>

          <form
            role="search"
            className="w-full max-w-2xl rounded-2xl bg-white/95 p-3 shadow-xl shadow-black/20 backdrop-blur"
            onSubmit={handleSearch}
          >
            <div className="mb-3 flex flex-wrap items-center justify-between gap-2">
              <div className="flex flex-wrap gap-1.5">
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
                    {tab.label} <span lang="ne" className="opacity-70">({tab.label_ne})</span>
                  </button>
                ))}
              </div>
              <div className="flex items-center gap-1 rounded-lg bg-stone-100 p-0.5 text-[11px] font-semibold">
                <button
                  type="button"
                  onClick={() => setUnitSystem('traditional')}
                  className={unitSystem === 'traditional' ? 'rounded-md bg-white px-2 py-1 text-trust-700 shadow-sm' : 'px-2 py-1 text-ink-700/60'}
                >
                  Aana / Ropani
                </button>
                <button
                  type="button"
                  onClick={() => setUnitSystem('metric')}
                  className={unitSystem === 'metric' ? 'rounded-md bg-white px-2 py-1 text-trust-700 shadow-sm' : 'px-2 py-1 text-ink-700/60'}
                >
                  Sq. Ft
                </button>
              </div>
            </div>
            <div className="grid grid-cols-1 gap-2 sm:grid-cols-3">
              <label className="flex flex-col gap-0.5 rounded-lg border border-stone-200 px-3 py-1">
                <span className="text-[10px] font-semibold uppercase tracking-wide text-ink-700/50">City or neighborhood</span>
                <span className="flex items-center gap-1.5">
                  <MapPin className="h-3.5 w-3.5 shrink-0 text-ink-700/50" aria-hidden="true" />
                  <select
                    value={cityId}
                    onChange={(e) => setCityId(e.target.value)}
                    className="h-7 w-full min-w-0 bg-transparent text-sm text-ink-900 focus:outline-none"
                  >
                    <option value="">Kathmandu Valley (All)</option>
                    {municipalities?.map((m) => (
                      <option key={m.id} value={m.id}>
                        {m.name}
                      </option>
                    ))}
                  </select>
                </span>
              </label>
              <label className="flex flex-col gap-0.5 rounded-lg border border-stone-200 px-3 py-1">
                <span className="text-[10px] font-semibold uppercase tracking-wide text-ink-700/50">Subtype &amp; structure</span>
                <select
                  value={subtype}
                  onChange={(e) => setSubtype(e.target.value)}
                  className="h-7 w-full min-w-0 bg-transparent text-sm text-ink-900 focus:outline-none"
                >
                  {PROPERTY_SUBTYPES.map((s) => (
                    <option key={s.value} value={s.value}>
                      {s.label}
                    </option>
                  ))}
                </select>
              </label>
              <label className="flex flex-col gap-0.5 rounded-lg border border-stone-200 px-3 py-1">
                <span className="text-[10px] font-semibold uppercase tracking-wide text-ink-700/50">Budget threshold</span>
                <select
                  value={budgetIndex}
                  onChange={(e) => setBudgetIndex(Number(e.target.value))}
                  className="h-7 w-full min-w-0 bg-transparent text-sm text-ink-900 focus:outline-none"
                >
                  {BUDGET_BANDS.map((band, i) => (
                    <option key={band.label} value={i}>
                      {band.label}
                    </option>
                  ))}
                </select>
              </label>
            </div>
            <Button type="submit" size="lg" className="mt-2 w-full">
              <Search className="h-4 w-4" />
              Search {platformStats ? `${formatCompactCount(platformStats.published_listings)}+ ` : ''}Properties
            </Button>
          </form>

          {hotspots.length > 0 && (
            <div className="flex flex-wrap items-center justify-center gap-2 text-xs text-white/70">
              <span className="font-medium text-white/50">Popular hotspots:</span>
              {hotspots.map((n) => (
                <Link
                  key={n.id}
                  to={`/neighborhoods/${n.id}`}
                  className="rounded-full border border-white/20 bg-white/10 px-3 py-1 font-medium text-white backdrop-blur-sm transition-colors hover:bg-white/20"
                >
                  {n.name}
                </Link>
              ))}
            </div>
          )}
        </div>
      </section>

      <AlertSignupBanner />

      <BannerCarousel />

      <FeaturedListings filters={heroFilters} cityName={heroCityName} />

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

/** Live preview of what the hero form above is currently set to — never a
 * static "newest across all of Nepal" list, or picking a city there would
 * visibly do nothing to the very next thing on the page. See the
 * `heroFilters` comment in `Home()`. */
function FeaturedListings({ filters, cityName }: { filters: SearchFilters; cityName?: string }) {
  const { data, isPending, isError, refetch } = useListingSearch({ sort: 'newest', ...filters })
  const listings = data?.data.slice(0, 6) ?? []

  if (isPending) return <PropertyGridSkeleton count={6} />
  if (isError) return <ErrorState onRetry={refetch} description="Couldn't load listings right now." />
  if (listings.length === 0) {
    return cityName ? (
      <EmptyState
        title={`No listings in ${cityName} yet`}
        description="Try another city, or check back soon — new listings are added regularly."
      />
    ) : null
  }

  return (
    <section>
      <div className="mb-4 flex items-end justify-between gap-3">
        <div>
          <h2 className="font-display text-2xl font-semibold text-ink-900">
            Featured &amp; Verified Listings{cityName ? ` in ${cityName}` : ''}
          </h2>
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
    <section className="grid grid-cols-1 gap-6 rounded-card border border-stone-200 bg-white p-6 sm:p-8 lg:grid-cols-2">
      <div>
        <span className="text-xs font-semibold uppercase tracking-wide text-trust-700">
          Nepal's benchmark real estate registry
        </span>
        <h2 className="mt-1 font-display text-2xl font-semibold text-ink-900">Built for Transparency</h2>
        <p className="mt-1 text-sm text-ink-700/70">
          Every figure below is a live count from listings and accounts on this platform right now — not a marketing estimate.
        </p>
        <div className="mt-6 grid grid-cols-2 gap-6 sm:grid-cols-4 lg:grid-cols-2">
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
      </div>
      <LandPriceChart data={stats?.land_price_per_aana_by_city} />
    </section>
  )
}

/** Median NPR/Aana for currently published land listings, by city — a real
 * live snapshot, deliberately not framed as a multi-year "index": the
 * platform has no years of transaction history to trend against. */
function LandPriceChart({ data }: { data?: { municipality: string; median_price_per_aana: number; listing_count: number }[] }) {
  if (data && data.length === 0) return null

  const rows = data ?? []
  const max = Math.max(1, ...rows.map((r) => r.median_price_per_aana))

  return (
    <div className="rounded-card border border-stone-200 bg-stone-50 p-4">
      <p className="text-xs font-semibold uppercase tracking-wide text-ink-700/50">Live snapshot</p>
      <h3 className="font-display text-sm font-semibold text-ink-900">Median Land Price by City (NPR / Aana)</h3>
      {!data ? (
        <div className="mt-4 flex flex-col gap-3">
          {Array.from({ length: 4 }).map((_, i) => (
            <Skeleton key={i} className="h-6 w-full" />
          ))}
        </div>
      ) : (
        <div className="mt-4 flex flex-col gap-3">
          {rows.map((row) => (
            <div key={row.municipality} className="flex items-center gap-3">
              <span className="w-28 shrink-0 truncate text-xs text-ink-700/70" title={row.municipality}>
                {row.municipality}
              </span>
              <div className="h-4 flex-1 overflow-hidden rounded-full bg-stone-200">
                <div
                  className="h-full rounded-full bg-accent-500"
                  style={{ width: `${Math.max(6, (row.median_price_per_aana / max) * 100)}%` }}
                />
              </div>
              <span className="w-24 shrink-0 text-right text-xs font-semibold text-ink-900">
                {formatNprCompact(row.median_price_per_aana)}
              </span>
            </div>
          ))}
        </div>
      )}
      <p className="mt-3 text-[11px] text-ink-700/50">
        Median asking price ÷ area across currently published land listings on Ghar Nepal — a live snapshot, not a historical index.
      </p>
    </div>
  )
}

function InstallAppSection() {
  const { canInstall, promptInstall } = useInstallPrompt()

  return (
    <section className="flex flex-col items-center gap-4 rounded-card bg-trust-700 p-8 text-center sm:p-12">
      <span className="flex h-12 w-12 items-center justify-center rounded-full bg-white/15 text-white">
        <Smartphone className="h-6 w-6" aria-hidden="true" />
      </span>
      <h2 className="max-w-lg text-balance font-display text-2xl font-bold text-white sm:text-3xl">
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
