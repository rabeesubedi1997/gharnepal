import { useEffect, useState } from 'react'

// Chrome/Edge/Android fire this instead of showing their own install UI,
// letting a site show its own prompt at a moment of its choosing —
// TypeScript's DOM lib doesn't define it, since it's a non-standard extension.
interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>
}

/** Shared between the global bottom banner (InstallAppPrompt) and any
 * in-page "Install the app" call to action (e.g. the homepage) — both need
 * the same captured event, and only one `beforeinstallprompt` fires per
 * page load. Safari/iOS never fires this event at all; there `canInstall`
 * stays false forever, since no web API can trigger its "Add to Home
 * Screen" share-sheet action. */
export function useInstallPrompt() {
  const [deferredPrompt, setDeferredPrompt] = useState<BeforeInstallPromptEvent | null>(null)

  useEffect(() => {
    const handler = (e: Event) => {
      e.preventDefault()
      setDeferredPrompt(e as BeforeInstallPromptEvent)
    }
    window.addEventListener('beforeinstallprompt', handler)
    return () => window.removeEventListener('beforeinstallprompt', handler)
  }, [])

  const promptInstall = async () => {
    if (!deferredPrompt) return false
    await deferredPrompt.prompt()
    const { outcome } = await deferredPrompt.userChoice
    setDeferredPrompt(null)
    return outcome === 'accepted'
  }

  return { canInstall: !!deferredPrompt, promptInstall }
}
