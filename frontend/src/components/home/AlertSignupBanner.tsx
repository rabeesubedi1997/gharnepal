import { useState } from 'react'
import { Bell } from 'lucide-react'
import { useMunicipalities } from '../../lib/api/locations'
import { useCreateSavedSearch } from '../../lib/api/savedSearches'
import { usePlatformStats } from '../../lib/api/platformStats'
import { useCurrentUser } from '../../lib/api/auth'
import { useRequireAuth } from '../auth/AuthGateProvider'
import { formatCompactCount } from '../../design-system/tokens'
import { Button } from '../ui/Button'

/**
 * The mockup's "Instant & Daily Property Alerts" banner, rebuilt on the
 * alert pipeline that already exists (SavedSearch + WhatsApp/email/push
 * notification channels) rather than a fake unauthenticated capture form.
 * There is no anonymous "enter your number, get emailed forever" mailbox
 * behind the scenes — an alert here becomes a real SavedSearch on the
 * visitor's own account, delivered to the contact details already on file,
 * same as every other alert in the product.
 */
export function AlertSignupBanner() {
  const { data: user } = useCurrentUser()
  const { data: municipalities } = useMunicipalities()
  const { data: stats } = usePlatformStats()
  const requireAuth = useRequireAuth()
  const createSavedSearch = useCreateSavedSearch()
  const [municipalityId, setMunicipalityId] = useState('')
  const [done, setDone] = useState(false)

  const enableAlerts = () => {
    requireAuth(() => {
      const municipality = municipalities?.find((m) => String(m.id) === municipalityId)
      createSavedSearch.mutate(
        {
          name: municipality ? `New listings in ${municipality.name}` : 'New listings, anywhere',
          filters: municipalityId ? { municipality_id: Number(municipalityId) } : {},
          alert_frequency: 'instant',
        },
        { onSuccess: () => setDone(true) },
      )
    })
  }

  return (
    <section className="-mx-4 flex flex-col gap-4 bg-ink-900 px-4 py-8 text-white sm:-mx-6 sm:px-6 sm:py-10 lg:-mx-10 lg:flex-row lg:items-center lg:justify-between lg:px-10">
      <div className="max-w-xl">
        <span className="text-xs font-semibold uppercase tracking-wide text-accent-500">
          Automated real-time pipeline
        </span>
        <h2 className="mt-1 font-display text-2xl font-bold">Instant &amp; Daily Property Alerts</h2>
        <p className="mt-1.5 text-sm text-white/70">
          Get notified via WhatsApp, email, and browser push the moment a matching listing appears in
          your chosen city — or as a daily digest, your choice.
        </p>
      </div>

      <div className="flex w-full max-w-md flex-col gap-2">
        {done ? (
          <p className="rounded-lg bg-white/10 px-4 py-2.5 text-sm font-medium text-white">
            Alerts enabled — manage frequency any time from your dashboard.
          </p>
        ) : (
          <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
            <select
              value={municipalityId}
              onChange={(e) => setMunicipalityId(e.target.value)}
              className="h-11 w-full min-w-0 rounded-lg border border-white/20 bg-white/10 px-3 text-sm text-white focus:outline-none [&>option]:text-ink-900"
            >
              <option value="">Any city</option>
              {municipalities?.map((m) => (
                <option key={m.id} value={m.id}>
                  {m.name}
                </option>
              ))}
            </select>
            <Button
              type="button"
              variant="secondary"
              className="shrink-0 whitespace-nowrap"
              onClick={enableAlerts}
              disabled={createSavedSearch.isPending}
            >
              <Bell className="h-4 w-4" /> {user ? 'Enable alerts' : 'Log in to enable'}
            </Button>
          </div>
        )}
        {stats && stats.active_alert_subscriptions > 0 && (
          <p className="text-xs text-white/50">
            Zero-spam policy · {formatCompactCount(stats.active_alert_subscriptions)} active alert subscriptions
          </p>
        )}
      </div>
    </section>
  )
}
