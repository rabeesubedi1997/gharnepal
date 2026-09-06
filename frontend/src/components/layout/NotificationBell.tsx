import { useState } from 'react'
import { Link } from 'react-router-dom'
import { Bell } from 'lucide-react'
import { useMarkAllNotificationsRead, useMarkNotificationRead, useNotifications } from '../../lib/api/notifications'
import { EmptyState } from '../ui/EmptyState'

function describe(n: { type: string | null; data: Record<string, unknown> }): { text: string; href: string } {
  switch (n.type) {
    case 'listing_approved':
      return { text: (n.data.message as string) ?? 'Your listing was approved', href: `/listings/${n.data.listing_slug}` }
    case 'listing_rejected':
      return { text: (n.data.message as string) ?? 'Your listing was rejected', href: '/dashboard' }
    case 'new_message':
      return { text: (n.data.message as string) ?? 'New message', href: `/messages/${n.data.conversation_id}` }
    default:
      return { text: 'You have a new notification', href: '/dashboard' }
  }
}

export function NotificationBell() {
  const [open, setOpen] = useState(false)
  const { data } = useNotifications()
  const markRead = useMarkNotificationRead()
  const markAllRead = useMarkAllNotificationsRead()
  const unread = data?.meta.unread_count ?? 0

  return (
    <div className="relative">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        aria-label="Notifications"
        className="relative rounded-md p-2 text-ink-700 hover:bg-stone-100 hover:text-ink-900"
      >
        <Bell className="h-5 w-5" />
        {unread > 0 && (
          <span className="absolute right-0.5 top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-accent-600 px-1 text-[10px] font-medium text-white">
            {unread > 9 ? '9+' : unread}
          </span>
        )}
      </button>

      {open && (
        <>
          <div className="fixed inset-0 z-40" onClick={() => setOpen(false)} />
          <div className="absolute right-0 z-50 mt-2 w-80 rounded-card border border-stone-200 bg-white shadow-lg">
            <div className="flex items-center justify-between border-b border-stone-200 p-3">
              <p className="text-sm font-semibold text-ink-900">Notifications</p>
              {unread > 0 && (
                <button
                  type="button"
                  onClick={() => markAllRead.mutate()}
                  className="text-xs font-medium text-link-600 hover:text-link-700"
                >
                  Mark all read
                </button>
              )}
            </div>
            <div className="max-h-80 overflow-y-auto">
              {data?.data.length === 0 && (
                <div className="p-4">
                  <EmptyState title="No notifications" />
                </div>
              )}
              {data?.data.map((n) => {
                const { text, href } = describe(n)
                return (
                  <Link
                    key={n.id}
                    to={href}
                    onClick={() => {
                      if (!n.read_at) markRead.mutate(n.id)
                      setOpen(false)
                    }}
                    className={`block border-b border-stone-100 p-3 text-sm hover:bg-stone-100 ${n.read_at ? 'text-ink-700/70' : 'font-medium text-ink-900'}`}
                  >
                    {text}
                  </Link>
                )
              })}
            </div>
          </div>
        </>
      )}
    </div>
  )
}
