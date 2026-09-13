import { useState } from 'react'
import { Link } from 'react-router-dom'
import { Bell, BellOff, BellRing } from 'lucide-react'
import { useMarkAllNotificationsRead, useMarkNotificationRead, useNotifications } from '../../lib/api/notifications'
import { isPushSupported, useCurrentPushSubscription, useSubscribeToPush, useUnsubscribeFromPush } from '../../lib/api/push'
import { EmptyState } from '../ui/EmptyState'

function describe(n: { type: string | null; data: Record<string, unknown> }): { text: string; href: string } {
  switch (n.type) {
    case 'listing_approved':
      return { text: (n.data.message as string) ?? 'Your listing was approved', href: `/listings/${n.data.listing_slug}` }
    case 'listing_rejected':
      return { text: (n.data.message as string) ?? 'Your listing was rejected', href: '/dashboard' }
    case 'new_message':
      return { text: (n.data.message as string) ?? 'New message', href: `/messages/${n.data.conversation_id}` }
    case 'saved_search_match':
      return { text: (n.data.message as string) ?? 'A saved search has new matches', href: '/search' }
    case 'viewing_request_received':
      return { text: (n.data.message as string) ?? 'New viewing request', href: '/account/viewing-requests?as=host' }
    case 'viewing_request_updated':
      return { text: (n.data.message as string) ?? 'A viewing request was updated', href: '/account/viewing-requests' }
    default:
      return { text: (n.data.message as string) ?? 'You have a new notification', href: '/dashboard' }
  }
}

export function NotificationBell() {
  const [open, setOpen] = useState(false)
  const [pushError, setPushError] = useState<string | null>(null)
  const { data } = useNotifications()
  const markRead = useMarkNotificationRead()
  const markAllRead = useMarkAllNotificationsRead()
  const { data: pushSubscription } = useCurrentPushSubscription()
  const subscribeToPush = useSubscribeToPush()
  const unsubscribeFromPush = useUnsubscribeFromPush()
  const unread = data?.meta.unread_count ?? 0
  const isPushEnabled = !!pushSubscription

  const togglePush = () => {
    setPushError(null)
    if (isPushEnabled) {
      unsubscribeFromPush.mutate()
    } else {
      subscribeToPush.mutate(undefined, {
        onError: (error) => setPushError(error instanceof Error ? error.message : 'Could not enable notifications.'),
      })
    }
  }

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
            {isPushSupported() && (
              <div className="border-t border-stone-200 p-3">
                <button
                  type="button"
                  onClick={togglePush}
                  disabled={subscribeToPush.isPending || unsubscribeFromPush.isPending}
                  className="flex w-full items-center gap-2 text-xs font-medium text-ink-700/70 hover:text-ink-900"
                >
                  {isPushEnabled ? <BellRing className="h-3.5 w-3.5 text-trust-700" /> : <BellOff className="h-3.5 w-3.5" />}
                  {isPushEnabled ? 'Browser notifications on — click to turn off' : 'Enable browser notifications'}
                </button>
                {pushError && <p className="mt-1 text-xs text-danger-600">{pushError}</p>}
              </div>
            )}
          </div>
        </>
      )}
    </div>
  )
}
