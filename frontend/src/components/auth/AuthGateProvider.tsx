import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from 'react'
import { useCurrentUser } from '../../lib/api/auth'
import { AuthModal } from './AuthModal'

interface PendingAuth {
  action: () => void
  message?: string
}

interface AuthGateApi {
  /** Same shape as the old hand-rolled `requireAuth` helpers it replaces —
   * call sites don't need to change. Runs `action` immediately if a user is
   * already loaded; otherwise opens the inline auth modal and runs it right
   * after a successful login/register, with no page navigation either way. */
  requireAuth: (action: () => void, opts?: { message?: string }) => void
}

const AuthGateContext = createContext<AuthGateApi | null>(null)

export function AuthGateProvider({ children }: { children: ReactNode }) {
  const { data: user } = useCurrentUser()
  const [pending, setPending] = useState<PendingAuth | null>(null)

  const requireAuth = useCallback(
    (action: () => void, opts?: { message?: string }) => {
      if (user) {
        action()
        return
      }
      setPending({ action, message: opts?.message })
    },
    [user],
  )

  const handleAuthenticated = useCallback(() => {
    const action = pending?.action
    setPending(null)
    // Let the modal's own close animation/state settle before the resumed
    // action opens another modal (e.g. the message/viewing modal) on top.
    if (action) setTimeout(action, 0)
  }, [pending])

  const api = useMemo<AuthGateApi>(() => ({ requireAuth }), [requireAuth])

  return (
    <AuthGateContext.Provider value={api}>
      {children}
      <AuthModal
        open={!!pending}
        message={pending?.message}
        onClose={() => setPending(null)}
        onAuthenticated={handleAuthenticated}
      />
    </AuthGateContext.Provider>
  )
}

export function useRequireAuth(): (action: () => void, opts?: { message?: string }) => void {
  const ctx = useContext(AuthGateContext)
  if (!ctx) throw new Error('useRequireAuth must be used within an AuthGateProvider')
  return ctx.requireAuth
}
