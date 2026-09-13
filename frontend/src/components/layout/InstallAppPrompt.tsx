import { useState } from 'react'
import { Download, X } from 'lucide-react'
import { Button } from '../ui/Button'
import { useInstallPrompt } from '../../lib/useInstallPrompt'

const DISMISSED_KEY = 'gharnepal:install-prompt-dismissed'

/** A small, dismissible bottom banner offering to install the PWA — only
 * ever appears on browsers that support it (Safari/iOS never fires this
 * event; the user installs via its own "Add to Home Screen" share-sheet
 * action instead, which no web API can trigger or detect). */
export function InstallAppPrompt() {
  const { canInstall, promptInstall } = useInstallPrompt()
  const [dismissed, setDismissed] = useState(() => {
    try {
      return localStorage.getItem(DISMISSED_KEY) === '1'
    } catch {
      return false
    }
  })

  if (!canInstall || dismissed) return null

  const dismiss = () => {
    setDismissed(true)
    try {
      localStorage.setItem(DISMISSED_KEY, '1')
    } catch {
      // best-effort only — worst case the banner reappears next visit
    }
  }

  return (
    <div className="fixed inset-x-0 bottom-0 z-40 flex items-center justify-between gap-3 border-t border-stone-200 bg-white px-4 py-3 shadow-[0_-2px_8px_rgba(0,0,0,0.06)] sm:inset-x-auto sm:bottom-4 sm:right-4 sm:max-w-sm sm:rounded-card sm:border print:hidden">
      <div className="flex items-center gap-3">
        <img src="/icons/icon-192.png" alt="" className="h-10 w-10 rounded-lg" />
        <div>
          <p className="text-sm font-semibold text-ink-900">Install Ghar Nepal</p>
          <p className="text-xs text-ink-700/60">Add to your home screen for quick, full-screen access.</p>
        </div>
      </div>
      <div className="flex items-center gap-1">
        <Button size="sm" onClick={() => promptInstall()}>
          <Download className="h-3.5 w-3.5" /> Install
        </Button>
        <button type="button" onClick={dismiss} aria-label="Dismiss" className="rounded-md p-1.5 text-ink-700/60 hover:bg-stone-100">
          <X className="h-4 w-4" />
        </button>
      </div>
    </div>
  )
}
