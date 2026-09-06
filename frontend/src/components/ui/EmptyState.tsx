import type { ReactNode } from 'react'
import { Inbox } from 'lucide-react'

interface EmptyStateProps {
  icon?: ReactNode
  title: string
  description?: string
  action?: ReactNode
}

export function EmptyState({ icon, title, description, action }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center gap-3 rounded-card border border-dashed border-stone-200 bg-white px-6 py-12 text-center">
      <div className="text-ink-700/40">{icon ?? <Inbox className="h-10 w-10" aria-hidden="true" />}</div>
      <h3 className="font-display text-lg font-semibold text-ink-900">{title}</h3>
      {description && <p className="max-w-sm text-sm text-ink-700/70">{description}</p>}
      {action}
    </div>
  )
}
