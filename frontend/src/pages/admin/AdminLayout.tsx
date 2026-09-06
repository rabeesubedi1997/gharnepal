import { useState } from 'react'
import { Link, NavLink, Outlet, useNavigate } from 'react-router-dom'
import { clsx } from 'clsx'
import {
  Building2,
  ClipboardList,
  Copy,
  Flag,
  GalleryHorizontal,
  Home,
  LayoutDashboard,
  ListChecks,
  LogOut,
  MapPin,
  Menu,
  MessageSquareText,
  Receipt,
  ShieldCheck,
  Star,
  Users,
  X,
} from 'lucide-react'
import { useCurrentUser, useLogout } from '../../lib/api/auth'

const NAV_GROUPS = [
  {
    title: 'Overview',
    items: [
      { to: '/admin/dashboard', label: 'Dashboard', icon: LayoutDashboard },
      { to: '/admin/banners', label: 'Homepage banners', icon: GalleryHorizontal },
    ],
  },
  {
    title: 'People',
    items: [
      { to: '/admin/users', label: 'Users', icon: Users },
      { to: '/admin/agencies', label: 'Agencies', icon: Building2 },
    ],
  },
  {
    title: 'Listings & locations',
    items: [
      { to: '/admin/listings/pending', label: 'Pending listings', icon: ClipboardList },
      { to: '/admin/duplicate-flags', label: 'Duplicate flags', icon: Copy },
      { to: '/admin/locations', label: 'Locations', icon: MapPin },
      { to: '/admin/neighborhoods', label: 'Neighborhoods', icon: MapPin },
      { to: '/admin/amenities', label: 'Amenities', icon: ListChecks },
    ],
  },
  {
    title: 'Trust & safety',
    items: [
      { to: '/admin/reports', label: 'Reports', icon: Flag },
      { to: '/admin/verifications', label: 'Verifications', icon: ShieldCheck },
      { to: '/admin/community-notes', label: 'Community notes', icon: MessageSquareText },
      { to: '/admin/ratings', label: 'Ratings & reviews', icon: Star },
    ],
  },
  {
    title: 'Finance',
    items: [{ to: '/admin/payments', label: 'Payments', icon: Receipt }],
  },
]

const FLAT_NAV = NAV_GROUPS.flatMap((g) => g.items)

function NavLinks({ onNavigate }: { onNavigate?: () => void }) {
  return (
    <nav className="flex-1 overflow-y-auto px-3 py-4">
      {NAV_GROUPS.map((group) => (
        <div key={group.title} className="mb-5">
          <p className="mb-1.5 px-2.5 text-xs font-semibold uppercase tracking-wide text-ink-700/40">{group.title}</p>
          <div className="flex flex-col gap-0.5">
            {group.items.map(({ to, label, icon: Icon }) => (
              <NavLink
                key={to}
                to={to}
                onClick={onNavigate}
                className={({ isActive }) =>
                  clsx(
                    'flex items-center gap-2.5 rounded-lg px-2.5 py-2 text-sm font-medium transition-colors',
                    isActive ? 'bg-trust-100 text-trust-700' : 'text-ink-700 hover:bg-stone-100',
                  )
                }
              >
                <Icon className="h-4 w-4 shrink-0" aria-hidden="true" /> {label}
              </NavLink>
            ))}
          </div>
        </div>
      ))}
    </nav>
  )
}

export function AdminLayout() {
  const { data: user } = useCurrentUser()
  const logout = useLogout()
  const navigate = useNavigate()
  const [mobileOpen, setMobileOpen] = useState(false)

  const handleLogout = () => {
    logout.mutate(undefined, { onSuccess: () => navigate('/') })
  }

  return (
    <div className="flex min-h-screen bg-stone-50">
      {/* Desktop sidebar */}
      <aside className="hidden w-64 shrink-0 flex-col border-r border-stone-200 bg-white lg:flex">
        <div className="flex h-16 items-center gap-2 border-b border-stone-200 px-5">
          <ShieldCheck className="h-5 w-5 text-trust-700" aria-hidden="true" />
          <span className="font-display text-base font-semibold text-ink-900">Ghar Nepal Admin</span>
        </div>
        <NavLinks />
        <div className="border-t border-stone-200 p-3">
          <Link to="/" className="flex items-center gap-2.5 rounded-lg px-2.5 py-2 text-sm font-medium text-ink-700 hover:bg-stone-100">
            <Home className="h-4 w-4" aria-hidden="true" /> Back to site
          </Link>
        </div>
      </aside>

      {/* Mobile slide-over sidebar */}
      {mobileOpen && (
        <div className="fixed inset-0 z-50 lg:hidden">
          <div className="absolute inset-0 bg-ink-900/40" onClick={() => setMobileOpen(false)} aria-hidden="true" />
          <aside className="relative flex h-full w-72 flex-col bg-white shadow-lg">
            <div className="flex h-16 items-center justify-between border-b border-stone-200 px-4">
              <span className="font-display text-base font-semibold text-ink-900">Ghar Nepal Admin</span>
              <button type="button" onClick={() => setMobileOpen(false)} aria-label="Close menu" className="rounded-md p-1.5 text-ink-700 hover:bg-stone-100">
                <X className="h-5 w-5" />
              </button>
            </div>
            <NavLinks onNavigate={() => setMobileOpen(false)} />
            <div className="border-t border-stone-200 p-3">
              <Link to="/" className="flex items-center gap-2.5 rounded-lg px-2.5 py-2 text-sm font-medium text-ink-700 hover:bg-stone-100">
                <Home className="h-4 w-4" aria-hidden="true" /> Back to site
              </Link>
            </div>
          </aside>
        </div>
      )}

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex h-16 items-center justify-between border-b border-stone-200 bg-white px-4 lg:px-6">
          <button
            type="button"
            onClick={() => setMobileOpen(true)}
            aria-label="Open menu"
            className="rounded-md p-1.5 text-ink-900 lg:hidden"
          >
            <Menu className="h-5 w-5" />
          </button>
          <span className="font-display text-sm font-semibold text-ink-900 lg:hidden">Admin</span>
          <div className="flex items-center gap-3">
            <span className="hidden text-sm text-ink-700/70 sm:inline">{user?.name}</span>
            <button
              type="button"
              onClick={handleLogout}
              className="flex items-center gap-1.5 rounded-lg px-2.5 py-1.5 text-sm font-medium text-ink-700 hover:bg-stone-100"
            >
              <LogOut className="h-4 w-4" aria-hidden="true" /> <span className="hidden sm:inline">Log out</span>
            </button>
          </div>
        </header>

        {/* Compact tab strip on mobile for quick jumps without opening the drawer */}
        <nav className="flex gap-1 overflow-x-auto border-b border-stone-200 bg-white px-3 py-2 lg:hidden" aria-label="Admin sections">
          {FLAT_NAV.map(({ to, label }) => (
            <NavLink
              key={to}
              to={to}
              className={({ isActive }) =>
                clsx(
                  'shrink-0 rounded-full px-3 py-1 text-xs font-medium',
                  isActive ? 'bg-trust-100 text-trust-700' : 'text-ink-700/70 hover:bg-stone-100',
                )
              }
            >
              {label}
            </NavLink>
          ))}
        </nav>

        <main className="flex-1 overflow-y-auto p-4 lg:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
