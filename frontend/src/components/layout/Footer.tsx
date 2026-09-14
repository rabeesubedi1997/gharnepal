import { Link } from 'react-router-dom'
import { useMunicipalities } from '../../lib/api/locations'
import { useBranding } from '../../lib/api/branding'
import { useInstallPrompt } from '../../lib/useInstallPrompt'

const PROPERTY_CLASSES = [
  { to: '/buy?property_type=house', label: 'Houses & Bungalows' },
  { to: '/buy?property_type=apartment', label: 'Apartments' },
  { to: '/rooms', label: 'Rooms' },
  { to: '/land', label: 'Land & Agricultural Plots' },
  { to: '/commercial', label: 'Commercial Spaces' },
]

const TOOLS = [
  { to: '/calculators/rental', label: 'Rental cost calculator' },
  { to: '/calculators/purchase', label: 'Purchase cost calculator' },
  { to: '/neighborhoods', label: 'Neighborhood explorer' },
  { to: '/property-requests', label: 'Property requests' },
  { to: '/blog', label: 'Blog' },
]

export function Footer() {
  // Real municipalities the platform actually covers, not a hardcoded
  // "Top Hubs & Valleys" list that could drift from what's really seeded.
  const { data: municipalities } = useMunicipalities()
  const { data: branding } = useBranding()
  const { canInstall, promptInstall } = useInstallPrompt()
  const topHubs = [...(municipalities ?? [])].slice(0, 6)
  const siteName = branding?.site_name ?? 'Ghar Nepal'

  return (
    <footer className="border-t border-stone-200 bg-white">
      <div className="mx-auto grid max-w-[1440px] grid-cols-1 gap-8 px-4 py-10 sm:grid-cols-4 sm:px-6 lg:px-10">
        <div>
          <p className="font-display text-lg font-semibold text-trust-700">{siteName}</p>
          <p className="mt-2 text-sm text-ink-700/70">
            Nepal's benchmark real estate ecosystem — streamlining transparent freehold and
            rental transactions across the country's major valleys.
          </p>
        </div>

        <div>
          <p className="text-sm font-semibold text-ink-900">Top Hubs &amp; Valleys</p>
          <ul className="mt-3 flex flex-col gap-2">
            {topHubs.map((m) => (
              <li key={m.id}>
                <Link to={`/search?municipality_id=${m.id}`} className="text-sm text-ink-700/80 hover:text-trust-700">
                  {m.name}
                </Link>
              </li>
            ))}
          </ul>
        </div>

        <div>
          <p className="text-sm font-semibold text-ink-900">Property Classes</p>
          <ul className="mt-3 flex flex-col gap-2">
            {PROPERTY_CLASSES.map((link) => (
              <li key={link.to}>
                <Link to={link.to} className="text-sm text-ink-700/80 hover:text-trust-700">
                  {link.label}
                </Link>
              </li>
            ))}
          </ul>
        </div>

        <div>
          <p className="text-sm font-semibold text-ink-900">Mobile &amp; Support</p>
          <p className="mt-3 text-sm text-ink-700/70">
            Install Ghar Nepal like an app for real-time listing alerts and offline browsing —
            no app store required.
          </p>
          {canInstall && (
            <button
              type="button"
              onClick={() => promptInstall()}
              className="mt-2 inline-flex items-center rounded-md border border-trust-700 px-3 py-1.5 text-xs font-semibold text-trust-700 hover:bg-trust-100"
            >
              Install the app
            </button>
          )}
          <ul className="mt-3 flex flex-col gap-2">
            {TOOLS.map((link) => (
              <li key={link.to}>
                <Link to={link.to} className="text-sm text-ink-700/80 hover:text-trust-700">
                  {link.label}
                </Link>
              </li>
            ))}
          </ul>
        </div>
      </div>

      <div className="mx-auto max-w-[1440px] border-t border-stone-200 px-4 py-4 text-center text-xs text-ink-700/60 sm:px-6 lg:px-10">
        <span>&copy; {new Date().getFullYear()} {siteName}. All rights reserved.</span>
      </div>
    </footer>
  )
}
