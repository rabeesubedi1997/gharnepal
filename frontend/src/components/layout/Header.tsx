import { useState } from 'react'
import { Link, NavLink, useNavigate } from 'react-router-dom'
import { Heart, Home, LogOut, Menu, MessageCircle, Plus, X } from 'lucide-react'
import { clsx } from 'clsx'
import { ButtonLink } from '../ui/Button'
import { useCurrentUser, useLogout } from '../../lib/api/auth'
import { NotificationBell } from './NotificationBell'

const primaryNav = [
  { to: '/buy', label: 'Buy' },
  { to: '/rent', label: 'Rent' },
  { to: '/rooms', label: 'Rooms' },
  { to: '/land', label: 'Land' },
  { to: '/commercial', label: 'Commercial' },
  { to: '/neighborhoods', label: 'Explore neighborhoods' },
  { to: '/agents', label: 'Agents' },
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
      <div className="mx-auto flex h-16 max-w-[1440px] items-center justify-between gap-4 px-4 sm:px-6 lg:px-10">
        <Link to="/" className="flex shrink-0 items-center gap-2 font-display text-lg font-semibold text-trust-700">
          <Home className="h-6 w-6" aria-hidden="true" />
          Ghar Nepal
        </Link>

        <nav className="hidden items-center gap-1 lg:flex" aria-label="Primary">
          {primaryNav.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                clsx(
                  'rounded-md px-3 py-2 text-sm font-medium transition-colors',
                  isActive ? 'text-trust-700' : 'text-ink-700 hover:text-ink-900',
                )
              }
            >
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="hidden items-center gap-2 lg:flex">
          <IconLink to="/saved" label="Saved" icon={<Heart className="h-5 w-5" />} />
          <IconLink to="/messages" label="Messages" icon={<MessageCircle className="h-5 w-5" />} />
          <ButtonLink to="/post-property" size="sm" variant="secondary">
            <Plus className="h-4 w-4" /> Post property
          </ButtonLink>
          {user ? (
            <>
              <NotificationBell />
              <Link to="/dashboard" className="text-sm font-medium text-ink-900 hover:text-trust-700">
                {user.name.split(' ')[0]}
              </Link>
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
              user ? { to: '/dashboard', label: 'Dashboard' } : { to: '/login', label: 'Log in' },
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
