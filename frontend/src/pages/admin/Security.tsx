import { useState } from 'react'
import { Mail, ShieldAlert } from 'lucide-react'
import { useAdminSecurity, useSendTestEmail, useUpdateSecurity } from '../../lib/api/security'
import { getErrorMessage } from '../../lib/api/errors'
import { AdminPageHeader } from '../../components/admin/AdminPageHeader'
import { Card } from '../../components/ui/Card'
import { Button } from '../../components/ui/Button'
import { Input } from '../../components/ui/Input'
import { ErrorState } from '../../components/ui/ErrorState'
import { Skeleton } from '../../components/ui/Skeleton'

export function Security() {
  const { data, isPending, isError, refetch } = useAdminSecurity()
  // Two independent mutation instances — sharing one meant clicking the
  // toggle also flipped the "Save keys" button into its loading state (and
  // vice versa), and gave the toggle itself no loading/error feedback of
  // its own, so a slow or failed request just looked like nothing happened.
  const toggleUpdate = useUpdateSecurity()
  const keysUpdate = useUpdateSecurity()
  const testEmail = useSendTestEmail()

  const [siteKey, setSiteKey] = useState('')
  const [secretKey, setSecretKey] = useState('')
  const [keysError, setKeysError] = useState<string | null>(null)
  const [saved, setSaved] = useState(false)
  const [toggleError, setToggleError] = useState<string | null>(null)

  // Reflects the server's last-known state, not local intent — while a
  // toggle request is in flight the switch still shows the pre-click
  // state (see the pending overlay below) instead of guessing.
  const enabled = data?.recaptcha_enabled ?? false

  const handleToggle = (next: boolean) => {
    if (toggleUpdate.isPending) return // one flip at a time — no racing double-clicks
    setToggleError(null)
    toggleUpdate.mutate(
      { recaptcha_enabled: next },
      { onError: (e) => setToggleError(getErrorMessage(e)) },
    )
  }

  const handleSaveKeys = () => {
    setKeysError(null)
    setSaved(false)
    keysUpdate.mutate(
      { recaptcha_site_key: siteKey.trim() || undefined, recaptcha_secret_key: secretKey.trim() || undefined },
      {
        onSuccess: () => {
          setSaved(true)
          setSiteKey('')
          setSecretKey('')
        },
        onError: (e) => setKeysError(getErrorMessage(e)),
      },
    )
  }

  if (isPending) {
    return (
      <div className="flex flex-col gap-6">
        <AdminPageHeader icon={ShieldAlert} title="Security" description="Bot protection and outbound email." />
        <Skeleton className="h-64 w-full" />
      </div>
    )
  }

  return (
    <div className="flex flex-col gap-6">
      <AdminPageHeader
        icon={ShieldAlert}
        title="Security"
        description="Registration bot protection and a way to check outbound email actually works."
      />

      {isError && <ErrorState onRetry={refetch} />}

      <Card className="flex flex-col gap-4 p-4">
        <div className="flex items-start justify-between gap-4">
          <div>
            <h2 className="font-display text-base font-semibold text-ink-900">"I'm not a robot" check (reCAPTCHA)</h2>
            <p className="mt-1 text-xs text-ink-700/60">
              Nothing currently stops a script from creating accounts in a loop. Add your Google reCAPTCHA v2 keys below, then
              turn this on — registration starts requiring the checkbox the moment it's active.
            </p>
          </div>
          <div className="flex shrink-0 items-center gap-2">
            <span className="text-[11px] font-medium text-ink-700/60">{enabled ? 'On' : 'Off'}</span>
            <button
              type="button"
              role="switch"
              aria-checked={enabled}
              aria-busy={toggleUpdate.isPending}
              disabled={!data?.recaptcha_site_key || !data?.recaptcha_secret_configured || toggleUpdate.isPending}
              onClick={() => handleToggle(!enabled)}
              className={`relative h-6 w-11 shrink-0 rounded-full transition-colors disabled:cursor-not-allowed disabled:opacity-40 ${enabled ? 'bg-trust-700' : 'bg-stone-300'}`}
            >
              <span
                className={`absolute top-0.5 flex h-5 w-5 items-center justify-center rounded-full bg-white transition-transform ${enabled ? 'translate-x-5' : 'translate-x-0.5'}`}
              >
                {toggleUpdate.isPending && (
                  <span className="h-3 w-3 animate-spin rounded-full border-2 border-stone-300 border-t-trust-700" />
                )}
              </span>
            </button>
          </div>
        </div>

        {toggleError && <p className="text-sm text-danger-600">{toggleError}</p>}

        {data && !data.recaptcha_site_key && (
          <p className="text-xs text-ink-700/60">
            Get a free site key + secret key at{' '}
            <a
              href="https://www.google.com/recaptcha/admin/create"
              target="_blank"
              rel="noreferrer"
              className="text-link-600 underline hover:text-link-700"
            >
              google.com/recaptcha/admin
            </a>{' '}
            — choose reCAPTCHA v2, "I'm not a robot" Checkbox.
          </p>
        )}

        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <Input
            label="Site key"
            placeholder={data?.recaptcha_site_key ?? 'Not set'}
            value={siteKey}
            onChange={(e) => setSiteKey(e.target.value)}
          />
          <Input
            label="Secret key"
            placeholder={data?.recaptcha_secret_configured ? '•••••••••••• (set — leave blank to keep it)' : 'Not set'}
            value={secretKey}
            onChange={(e) => setSecretKey(e.target.value)}
          />
        </div>

        {keysError && <p className="text-sm text-danger-600">{keysError}</p>}
        {saved && <p className="text-sm text-success-600">Saved.</p>}
        <Button className="self-start" size="sm" variant="outline" isLoading={keysUpdate.isPending} onClick={handleSaveKeys}>
          Save keys
        </Button>
      </Card>

      <Card className="flex flex-col gap-3 p-4">
        <div className="flex items-center gap-2">
          <Mail className="h-4 w-4 text-ink-700/60" aria-hidden="true" />
          <h2 className="font-display text-base font-semibold text-ink-900">Outbound email</h2>
        </div>
        <p className="text-xs text-ink-700/60">
          If alert emails aren't arriving, the most common cause is <code>MAIL_MAILER</code> still set to <code>log</code> (the
          safe default) even after SMTP credentials were added to the live <code>.env</code> — SMTP host/port/username/password
          alone don't switch it over. Send yourself a test email right now to check the current setup.
        </p>
        <Button
          size="sm"
          variant="outline"
          className="self-start"
          isLoading={testEmail.isPending}
          onClick={() => testEmail.mutate()}
        >
          Send me a test email
        </Button>
        {testEmail.data && (
          <div className={`rounded-lg p-3 text-sm ${testEmail.data.sent ? 'bg-success-100/40 text-success-700' : 'bg-danger-100/40 text-danger-700'}`}>
            {testEmail.data.sent ? (
              <p>
                Sent to {testEmail.data.to} via mailer "{testEmail.data.mailer}". Check your inbox (and spam folder).
              </p>
            ) : (
              <>
                <p className="font-medium">Failed via mailer "{testEmail.data.mailer}":</p>
                <p className="mt-1 font-mono text-xs">{testEmail.data.error}</p>
              </>
            )}
          </div>
        )}
      </Card>
    </div>
  )
}
