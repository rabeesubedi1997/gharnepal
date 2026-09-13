import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { HelmetProvider } from 'react-helmet-async'
import 'leaflet/dist/leaflet.css'
import './index.css'
import App from './App.tsx'
import { ToastProvider } from './components/ui/Toast'
import { AuthGateProvider } from './components/auth/AuthGateProvider'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
})

// Registers the offline-shell + push service worker as soon as the app
// boots — not gated on the user opting into push notifications (see
// lib/api/push.ts, which also registers it, idempotently, right before
// subscribing). Registering early means a visitor gets basic offline
// resilience on their very first visit, with no action needed from them.
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js').catch(() => {
      // Offline support is a progressive enhancement — nothing else in the
      // app depends on this succeeding (e.g. Safari's older SW quirks, or a
      // dev tool blocking it), so a failure here is silently non-fatal.
    })
  })
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <HelmetProvider>
      <QueryClientProvider client={queryClient}>
        <BrowserRouter>
          <ToastProvider>
            <AuthGateProvider>
              <App />
            </AuthGateProvider>
          </ToastProvider>
        </BrowserRouter>
      </QueryClientProvider>
    </HelmetProvider>
  </StrictMode>,
)
