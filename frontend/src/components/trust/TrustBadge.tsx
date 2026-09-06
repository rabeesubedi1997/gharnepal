import { useState } from 'react'
import { CheckCircle2, Shield, ShieldAlert, ShieldCheck, XCircle } from 'lucide-react'
import { clsx } from 'clsx'
import type { TrustScore } from '../../lib/api/trust'

function tier(score: number): { tone: string; icon: typeof Shield; label: string } {
  if (score >= 70) return { tone: 'bg-trust-100 text-trust-700', icon: ShieldCheck, label: 'Trusted' }
  if (score >= 40) return { tone: 'bg-warning-100 text-warning-600', icon: Shield, label: 'Fair trust' }
  return { tone: 'bg-danger-100 text-danger-600', icon: ShieldAlert, label: 'Low trust' }
}

/** Compact badge for cards — just the score, no explanation (keeps grids scannable). */
export function TrustScoreChip({ score }: { score: number }) {
  const { tone, icon: Icon } = tier(score)
  return (
    <span className={clsx('inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium', tone)}>
      <Icon className="h-3 w-3" aria-hidden="true" /> {score}
    </span>
  )
}

/** Full badge with a click-to-open explanation popover — for the listing detail page. */
export function TrustBadge({ trust }: { trust: TrustScore }) {
  const [open, setOpen] = useState(false)
  const { tone, icon: Icon, label } = tier(trust.score)

  return (
    <div className="relative inline-block">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className={clsx('inline-flex items-center gap-1.5 rounded-full px-3 py-1 text-sm font-medium', tone)}
      >
        <Icon className="h-4 w-4" aria-hidden="true" />
        {label} · {trust.score}/100
      </button>

      {open && (
        <>
          <div className="fixed inset-0 z-40" onClick={() => setOpen(false)} />
          <div className="absolute left-0 z-50 mt-2 w-80 rounded-card border border-stone-200 bg-white p-4 shadow-lg sm:w-96">
            <div className="mb-3 flex items-center justify-between">
              <p className="font-display text-sm font-semibold text-ink-900">Why this score?</p>
              {trust.is_overridden && <span className="text-xs text-ink-700/60">Adjusted by admin review</span>}
            </div>
            <ul className="flex flex-col gap-2.5">
              {trust.breakdown.map((f) => (
                <li key={f.key} className="flex items-start gap-2">
                  {f.points_awarded > 0 ? (
                    <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-success-600" aria-hidden="true" />
                  ) : (
                    <XCircle className="mt-0.5 h-4 w-4 shrink-0 text-ink-700/30" aria-hidden="true" />
                  )}
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center justify-between gap-2">
                      <p className="text-sm font-medium text-ink-900">{f.label}</p>
                      <p className="shrink-0 text-xs text-ink-700/60">{f.points_awarded}/{f.max_points}</p>
                    </div>
                    <p className="text-xs text-ink-700/60">{f.explanation}</p>
                  </div>
                </li>
              ))}
            </ul>
            <p className="mt-3 border-t border-stone-100 pt-2 text-xs text-ink-700/50">
              Computed from verified platform activity — not a government or legal guarantee.
            </p>
          </div>
        </>
      )}
    </div>
  )
}
