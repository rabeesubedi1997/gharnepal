// Service worker for both Web Push (see push.ts) and a basic offline PWA
// shell. There's no build-time precache manifest here (that needs a bundler
// plugin like vite-plugin-pwa, generating a hashed asset list at build
// time) — instead this uses runtime caching: static assets and pages get
// cached the first time they're actually fetched, so anything a visitor has
// already loaded once stays available offline. API responses are
// deliberately never cached here — serving stale JSON as if it were live
// (prices, availability, auth state) would be actively misleading; only the
// static shell (HTML/JS/CSS/fonts) benefits from this.

const CACHE_NAME = 'gharnepal-shell-v1'
const OFFLINE_URL = '/offline.html'
// Warmed on install so the very first offline visit still has something to
// show, even before the user has browsed anywhere.
const PRECACHE_URLS = ['/', OFFLINE_URL, '/manifest.webmanifest', '/favicon.svg']

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(PRECACHE_URLS))
      .then(() => self.skipWaiting()),
  )
})

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))))
      .then(() => self.clients.claim()),
  )
})

// Assets worth caching opportunistically once actually requested — page
// navigations, and the static building blocks of the app shell (script,
// style, font). Deliberately excludes 'image' (property photos and map
// tiles are numerous, large, and not part of "the shell") and anything
// that isn't a plain GET (API mutations, etc).
function isShellRequest(request) {
  if (request.method !== 'GET') return false
  if (request.mode === 'navigate') return true
  return ['script', 'style', 'font'].includes(request.destination)
}

self.addEventListener('fetch', (event) => {
  const { request } = event
  if (!isShellRequest(request)) return

  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request)
        .then((response) => {
          const copy = response.clone()
          caches.open(CACHE_NAME).then((cache) => cache.put(request, copy))
          return response
        })
        .catch(() => caches.match(request).then((cached) => cached || caches.match(OFFLINE_URL))),
    )
    return
  }

  // Stale-while-revalidate for static assets: serve the cached copy
  // instantly if there is one, and refresh it in the background — a script
  // or font rarely changes shape between visits, so instant-from-cache is
  // the right default even when online.
  event.respondWith(
    caches.match(request).then((cached) => {
      const network = fetch(request)
        .then((response) => {
          if (response.ok) {
            const copy = response.clone()
            caches.open(CACHE_NAME).then((cache) => cache.put(request, copy))
          }
          return response
        })
        .catch(() => cached)
      return cached || network
    }),
  )
})

self.addEventListener('push', (event) => {
  if (!event.data) return

  let payload
  try {
    payload = event.data.json()
  } catch {
    payload = { title: 'Ghar Nepal', body: event.data.text() }
  }

  const title = payload.title || 'Ghar Nepal'
  event.waitUntil(
    self.registration.showNotification(title, {
      body: payload.body,
      icon: '/favicon.svg',
      data: { url: payload.url || '/' },
    }),
  )
})

self.addEventListener('notificationclick', (event) => {
  event.notification.close()
  const url = event.notification.data?.url || '/'

  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clients) => {
      for (const client of clients) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          client.navigate(url)
          return client.focus()
        }
      }
      return self.clients.openWindow(url)
    }),
  )
})
