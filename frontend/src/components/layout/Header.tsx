import { useState } from 'react'
import { Link, NavLink, useNavigate } from 'react-router-dom'
import { Building2, Heart, Home, LogOut, Menu, MessageCircle, Plus, Settings, Sparkles, X } from 'lucide-react'
import { clsx } from 'clsx'
import { ButtonLink } from '../ui/Button'
import { useCurrentUser, useLogout } from '../../lib/api/auth'
import { NotificationBell } from './NotificationBell'

const primaryNav = [
  { to: '/buy', label: 'Buy' },
  { to: '/rent', label: 'Rent' },
  { to: '/commercial', label: 'Commercial' },
  { to: '/land', label: 'Land & Plots' },
  { to: '/agents', label: 'Agencies & Brokers' },
  { to: '/neighborhoods', label: 'Neighborhood Guides' },
]

export function Header() {
  const [mobileOpen, setMobileOpen] = useState(false)
  const { data: user } = useCurrentUser()
  const logout = useLogout()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout.mutate(undefined, { onSuccess: () => navigate('/') })
  }

  return (
    <header className="sticky top-0 z-40 border-b border-stone-200 bg-stone-50/95 backdrop-blur">
      <div className="mx-auto flex h-16 max-w-[1440px] items-center justify-between gap-3 px-4 sm:px-6 lg:px-10">
        <Link to="/" className="flex shrink-0 items-center gap-2">
          <span className="flex h-9 w-9 items-center justify-center rounded-lg bg-trust-700 text-white">
            <Home className="h-5 w-5" aria-hidden="true" />
          </span>
          <span className="flex flex-col leading-none">
            <span className="font-display text-base font-bold text-ink-900">GharNepal</span>
            <span className="text-[10px] font-semibold uppercase tracking-wider text-ink-700/50">Proptech Hub</span>
          </span>
        </Link>

        <nav className="hidden min-w-0 items-center gap-0 lg:flex" aria-label="Primary">
          {primaryNav.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                clsx(
                  'shrink-0 whitespace-nowrap rounded-md px-1 py-2 text-[13px] font-medium transition-colors xl:px-2.5 xl:text-sm',
                  isActive ? 'text-trust-700' : 'text-ink-700 hover:text-ink-900',
                )
              }
            >
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="hidden shrink-0 items-center gap-1 lg:flex">
          <IconLink to="/saved" label="Saved" icon={<Heart className="h-5 w-5" />} />
          <IconLink to="/messages" label="Messages" icon={<MessageCircle className="h-5 w-5" />} />
          <ButtonLink to="/post-property" size="sm" variant="primary" className="shrink-0 whitespace-nowrap">
            <Plus className="h-4 w-4" /> Post Free Property
          </ButtonLink>
          {user ? (
            <>
              <NotificationBell />
              <IconLink to="/account/match-results" label="Smart Match" icon={<Sparkles className="h-5 w-5" />} />
              {user.agency && (
                <IconLink to="/agency/dashboard" label="Agency dashboard" icon={<Building2 className="h-5 w-5" />} />
              )}
              <Link to="/dashboard" className="text-sm font-medium text-ink-900 hover:text-trust-700">
                {user.name.split(' ')[0]}
              </Link>
              <IconLink to="/account/settings" label="Account settings" icon={<Settings className="h-5 w-5" />} />
              <button
                type="button"
                onClick={handleLogout}
                aria-label="Log out"
                className="rounded-md p-2 text-ink-700 hover:bg-stone-100 hover:text-ink-900"
              >
                <LogOut className="h-4 w-4" />
              </button>
            </>
          ) : (
            <Link to="/login" className="text-sm font-medium text-ink-900 hover:text-trust-700">
              Log in
            </Link>
          )}
        </div>

        <button
          type="button"
          className="rounded-md p-2 text-ink-900 lg:hidden"
          aria-label={mobileOpen ? 'Close menu' : 'Open menu'}
          onClick={() => setMobileOpen((v) => !v)}
        >
          {mobileOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
        </button>
      </div>

      {mobileOpen && (
        <nav className="border-t border-stone-200 bg-stone-50 px-4 py-3 lg:hidden" aria-label="Primary">
          <ul className="flex flex-col gap-1">
            {[
              ...primaryNav,
              { to: '/saved', label: 'Saved' },
              { to: '/messages', label: 'Messages' },
              { to: '/post-property', label: 'Post property' },
              ...(user
                ? [
                    { to: '/account/match-results', label: 'Smart Match' },
                    ...(user.agency ? [{ to: '/agency/dashboard', label: 'Agency dashboard' }] : []),
                    { to: '/dashboard', label: 'Dashboard' },
                    { to: '/account/settings', label: 'Account settings' },
                  ]
                : [{ to: '/login', label: 'Log in' }]),
            ].map((item) => (
              <li key={item.to}>
                <NavLink
                  to={item.to}
                  onClick={() => setMobileOpen(false)}
                  className="block rounded-md px-3 py-2.5 text-sm font-medium text-ink-900 hover:bg-stone-100"
                >
                  {item.label}
                </NavLink>
              </li>
            ))}
            {user && (
              <li>
                <button
                  type="button"
                  onClick={() => {
                    setMobileOpen(false)
                    handleLogout()
                  }}
                  className="block w-full rounded-md px-3 py-2.5 text-left text-sm font-medium text-ink-900 hover:bg-stone-100"
                >
                  Log out
                </button>
              </li>
            )}
          </ul>
        </nav>
      )}
    </header>
  )
}

function IconLink({ to, label, icon }: { to: string; label: string; icon: React.ReactNode }) {
  return (
    <Link
      to={to}
      aria-label={label}
      className="rounded-md p-2 text-ink-700 transition-colors hover:bg-stone-100 hover:text-ink-900"
    >
      {icon}
    </Link>
  )
}
