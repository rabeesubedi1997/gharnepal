import { Link } from 'react-router-dom'

const columns = [
  {
    title: 'Explore',
    links: [
      { to: '/buy', label: 'Buy' },
      { to: '/rent', label: 'Rent' },
      { to: '/rooms', label: 'Rooms' },
      { to: '/land', label: 'Land' },
      { to: '/commercial', label: 'Commercial' },
    ],
  },
  {
    title: 'Tools',
    links: [
      { to: '/calculators/rental', label: 'Rental cost calculator' },
      { to: '/calculators/purchase', label: 'Purchase cost calculator' },
      { to: '/neighborhoods', label: 'Neighborhood explorer' },
      { to: '/agents', label: 'Find an agent' },
    ],
  },
  {
    title: 'Account',
    links: [
      { to: '/saved', label: 'Saved properties' },
      { to: '/messages', label: 'Messages' },
      { to: '/account/viewing-requests', label: 'Viewing requests' },
      { to: '/account/match-results', label: 'Smart matches' },
      { to: '/account/payments', label: 'Payment history' },
      { to: '/dashboard', label: 'Dashboard' },
    ],
  },
]

export function Footer() {
  return (
    <footer className="border-t border-stone-200 bg-white">
      <div className="mx-auto grid max-w-[1440px] grid-cols-2 gap-8 px-4 py-10 sm:grid-cols-4 sm:px-6 lg:px-10">
        <div className="col-span-2 sm:col-span-1">
          <p className="font-display text-lg font-semibold text-trust-700">Ghar Nepal</p>
          <p className="mt-2 text-sm text-ink-700/70">
            A verified Nepal property marketplace that helps people discover, compare, verify,
            and confidently act on property decisions.
          </p>
        </div>
        {columns.map((col) => (
          <div key={col.title}>
            <p className="text-sm font-semibold text-ink-900">{col.title}</p>
            <ul className="mt-3 flex flex-col gap-2">
              {col.links.map((link) => (
                <li key={link.to}>
                  <Link to={link.to} className="text-sm text-ink-700/80 hover:text-trust-700">
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>
      <div className="border-t border-stone-200 px-4 py-4 text-center text-xs text-ink-700/60">
        &copy; {new Date().getFullYear()} Ghar Nepal. All rights reserved.
      </div>
    </footer>
  )
}
