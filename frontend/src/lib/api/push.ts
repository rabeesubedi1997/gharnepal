import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'

/** Web Push's applicationServerKey wants a raw Uint8Array, not the base64url string the backend hands back. */
function urlBase64ToUint8Array(base64Url: string): Uint8Array<ArrayBuffer> {
  const padding = '='.repeat((4 - (base64Url.length % 4)) % 4)
  const base64 = (base64Url + padding).replace(/-/g, '+').replace(/_/g, '/')
  const raw = window.atob(base64)
  const bytes = new Uint8Array(new ArrayBuffer(raw.length))
  for (let i = 0; i < raw.length; i++) bytes[i] = raw.charCodeAt(i)
  return bytes
}

export function isPushSupported(): boolean {
  return 'serviceWorker' in navigator && 'PushManager' in window
}

async function fetchVapidPublicKey(): Promise<string> {
  const { data } = await apiClient.get<{ key: string | null }>('/push/vapid-public-key')
  if (!data.key) throw new Error('Push notifications are not configured on this server yet.')
  return data.key
}

/** Whether *this* browser already has an active push subscription — independent of whether the backend still has it recorded. */
export function useCurrentPushSubscription() {
  return useQuery({
    queryKey: ['push', 'subscription'],
    queryFn: async () => {
      const registration = await navigator.serviceWorker.register('/sw.js')
      return registration.pushManager.getSubscription()
    },
    enabled: isPushSupported(),
  })
}

export function useSubscribeToPush() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async () => {
      // Fetched fresh at call-time rather than read from a separately
      // rendered query's cache — this can fire (from the notification bell,
      // possibly right after login) before that query has had a chance to
      // resolve, so relying on its value directly raced and intermittently
      // failed with "not configured" even when the backend had a real key.
      const vapidKey = await fetchVapidPublicKey()

      const permission = await Notification.requestPermission()
      if (permission !== 'granted') throw new Error('Notification permission was not granted.')

      const registration = await navigator.serviceWorker.register('/sw.js')
      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(vapidKey),
      })

      await ensureCsrfCookie()
      await apiClient.post('/account/push-subscriptions', subscription.toJSON())
      return subscription
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['push', 'subscription'] }),
  })
}

export function useUnsubscribeFromPush() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: async () => {
      const registration = await navigator.serviceWorker.getRegistration('/sw.js')
      const subscription = await registration?.pushManager.getSubscription()
      if (!subscription) return

      await ensureCsrfCookie()
      await apiClient.delete('/account/push-subscriptions', { data: { endpoint: subscription.endpoint } })
      await subscription.unsubscribe()
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['push', 'subscription'] }),
  })
}
