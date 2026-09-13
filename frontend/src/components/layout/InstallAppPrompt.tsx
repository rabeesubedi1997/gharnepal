import { useEffect, useState } from 'react'
import { Download, X } from 'lucide-react'
import { Button } from '../ui/Button'

const DISMISSED_KEY = 'gharnepal:install-prompt-dismissed'

// Chrome/Edge/Android fire this instead of showing their own install UI,
// letting a site show its own prompt at a moment of its choosing —
// TypeScript's DOM lib doesn't define it, since it's a non-standard extension.
interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>
}

/** A small, dismissible bottom banner offering to install the PWA — only
 * ever appears on browsers that support it (Safari/iOS never fires this
 * event; the user installs via its own "Add to Home Screen" share-sheet
 * action instead, which no web API can trigger or detect). */
export function InstallAppPrompt() {
  const [deferredPrompt, setDeferredPrompt] = useState<BeforeInstallPromptEvent | null>(null)
  const [dismissed, setDismissed] = useState(() => {
    try {
      return localStorage.getItem(DISMISSED_KEY) === '1'
    } catch {
      return false
    }
  })

  useEffect(() => {
    const handler = (e: Event) => {
      e.preventDefault()
      setDeferredPrompt(e as BeforeInstallPromptEvent)
    }
    window.addEventListener('beforeinstallprompt', handler)
    return () => window.removeEventListener('beforeinstallprompt', handler)
  }, [])

  if (!deferredPrompt || dismissed) return null

  const dismiss = () => {
    setDismissed(true)
    try {
      localStorage.setItem(DISMISSED_KEY, '1')
    } catch {
      // best-effort only — worst case the banner reappears next visit
    }
  }

  const install = async () => {
    await deferredPrompt.prompt()
    await deferredPrompt.userChoice
    setDeferredPrompt(null)
  }

  return (
    <div className="fixed inset-x-0 bottom-0 z-40 flex items-center justify-between gap-3 border-t border-stone-200 bg-white px-4 py-3 shadow-[0_-2px_8px_rgba(0,0,0,0.06)] sm:inset-x-auto sm:bottom-4 sm:right-4 sm:max-w-sm sm:rounded-card sm:border">
      <div className="flex items-center gap-3">
        <img src="/icons/icon-192.png" alt="" className="h-10 w-10 rounded-lg" />
        <div>
          <p className="text-sm font-semibold text-ink-900">Install Ghar Nepal</p>
          <p className="text-xs text-ink-700/60">Add to your home screen for quick, full-screen access.</p>
        </div>
      </div>
      <div className="flex items-center gap-1">
        <Button size="sm" onClick={install}>
          <Download className="h-3.5 w-3.5" /> Install
        </Button>
        <button type="button" onClick={dismiss} aria-label="Dismiss" className="rounded-md p-1.5 text-ink-700/60 hover:bg-stone-100">
          <X className="h-4 w-4" />
        </button>
      </div>
    </div>
  )
}
