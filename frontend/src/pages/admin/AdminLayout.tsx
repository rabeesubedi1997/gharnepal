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
  Newspaper,
  Receipt,
  Search,
  ShieldCheck,
  Star,
  Users,
  X,
} from 'lucide-react'
import { useCurrentUser, useLogout } from '../../lib/api/auth'
import { ADMIN_TONE_ACTIVE_NAV, ADMIN_TONE_DOT, type AdminTone } from '../../components/admin/tones'

const NAV_GROUPS: { title: string; tone: AdminTone; items: { to: string; label: string; icon: typeof Users }[] }[] = [
  {
    title: 'Overview',
    tone: 'trust',
    items: [
      { to: '/admin/dashboard', label: 'Dashboard', icon: LayoutDashboard },
      { to: '/admin/banners', label: 'Homepage banners', icon: GalleryHorizontal },
      { to: '/admin/blog', label: 'Blog', icon: Newspaper },
    ],
  },
  {
    title: 'People',
    tone: 'trust',
    items: [
      { to: '/admin/users', label: 'Users', icon: Users },
      { to: '/admin/agencies', label: 'Agencies', icon: Building2 },
    ],
  },
  {
    title: 'Listings & locations',
    tone: 'trust',
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
    tone: 'warning',
    items: [
      { to: '/admin/reports', label: 'Reports', icon: Flag },
      { to: '/admin/verifications', label: 'Verifications', icon: ShieldCheck },
      { to: '/admin/community-notes', label: 'Community notes', icon: MessageSquareText },
      { to: '/admin/ratings', label: 'Ratings & reviews', icon: Star },
    ],
  },
  {
    title: 'Finance',
    tone: 'success',
    items: [{ to: '/admin/payments', label: 'Payments', icon: Receipt }],
  },
  {
    title: 'SEO & marketing',
    tone: 'trust',
    items: [{ to: '/admin/seo', label: 'SEO pages', icon: Search }],
  },
]

const FLAT_NAV = NAV_GROUPS.flatMap((g) => g.items.map((item) => ({ ...item, tone: g.tone })))

function NavLinks({ onNavigate }: { onNavigate?: () => void }) {
  return (
    <nav className="flex-1 overflow-y-auto px-3 py-4">
      {NAV_GROUPS.map((group) => (
        <div key={group.title} className="mb-5">
          <p className="mb-1.5 flex items-center gap-1.5 px-2.5 text-xs font-semibold uppercase tracking-wide text-ink-700/40">
            <span className={clsx('h-1.5 w-1.5 rounded-full', ADMIN_TONE_DOT[group.tone])} aria-hidden="true" />
            {group.title}
          </p>
          <div className="flex flex-col gap-0.5">
            {group.items.map(({ to, label, icon: Icon }) => (
              <NavLink
                key={to}
                to={to}
                onClick={onNavigate}
                className={({ isActive }) =>
                  clsx(
                    'flex items-center gap-2.5 rounded-lg border-l-[3px] px-2.5 py-2 text-sm font-medium transition-colors',
                    isActive ? ADMIN_TONE_ACTIVE_NAV[group.tone] : 'border-transparent text-ink-700 hover:bg-stone-100',
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

function SidebarMasthead() {
  return (
    <div className="flex items-center gap-2.5 bg-trust-700 px-5 py-4">
      <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-white/15 text-white">
        <ShieldCheck className="h-5 w-5" aria-hidden="true" />
      </span>
      <div>
        <p className="font-display text-base font-semibold leading-tight text-white">Ghar Nepal</p>
        <p className="text-[11px] font-semibold uppercase tracking-widest text-trust-100/80">Admin console</p>
      </div>
    </div>
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

  const initial = user?.name?.trim()?.[0]?.toUpperCase() ?? '?'

  return (
    <div className="flex min-h-screen bg-stone-50">
      {/* Desktop sidebar */}
      <aside className="hidden w-64 shrink-0 flex-col border-r border-stone-200 bg-white lg:flex">
        <SidebarMasthead />
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
            <div className="flex items-center justify-between bg-trust-700 pr-3">
              <SidebarMasthead />
              <button type="button" onClick={() => setMobileOpen(false)} aria-label="Close menu" className="rounded-md p-1.5 text-white/80 hover:bg-white/10 hover:text-white">
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
            <div className="hidden items-center gap-2 sm:flex">
              <span className="flex h-7 w-7 items-center justify-center rounded-full bg-accent-100 text-xs font-semibold text-accent-600">
                {initial}
              </span>
              <span className="text-sm text-ink-700/70">{user?.name}</span>
            </div>
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
          {FLAT_NAV.map(({ to, label, tone }) => (
            <NavLink
              key={to}
              to={to}
              className={({ isActive }) =>
                clsx(
                  'shrink-0 rounded-full px-3 py-1 text-xs font-medium',
                  isActive ? ADMIN_TONE_ACTIVE_NAV[tone] : 'border-transparent text-ink-700/70 hover:bg-stone-100',
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
