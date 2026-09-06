import type { ReactNode } from 'react'
import type { LucideIcon } from 'lucide-react'
import { clsx } from 'clsx'
import { ADMIN_TONE_BADGE, type AdminTone } from './tones'

export function AdminPageHeader({
  icon: Icon,
  title,
  description,
  tone = 'trust',
  action,
}: {
  icon: LucideIcon
  title: string
  description?: string
  tone?: AdminTone
  action?: ReactNode
}) {
  return (
    <div className="flex flex-wrap items-start justify-between gap-3 border-b border-stone-200 pb-5">
      <div className="flex items-start gap-3">
        <span className={clsx('flex h-11 w-11 shrink-0 items-center justify-center rounded-xl', ADMIN_TONE_BADGE[tone])}>
          <Icon className="h-5 w-5" aria-hidden="true" />
        </span>
        <div>
          <h1 className="font-display text-2xl font-semibold text-ink-900">{title}</h1>
          {description && <p className="mt-1 max-w-2xl text-sm text-ink-700/70">{description}</p>}
        </div>
      </div>
      {action && <div className="flex shrink-0 flex-wrap items-center gap-2">{action}</div>}
    </div>
  )
}
