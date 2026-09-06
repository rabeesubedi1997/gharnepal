import { AlertTriangle } from 'lucide-react'
import { Button } from './Button'

interface ErrorStateProps {
  title?: string
  description?: string
  onRetry?: () => void
}

export function ErrorState({
  title = 'Something went wrong',
  description = 'Please try again. If the problem continues, contact support.',
  onRetry,
}: ErrorStateProps) {
  return (
    <div className="flex flex-col items-center gap-3 rounded-card border border-danger-100 bg-danger-100/30 px-6 py-12 text-center">
      <AlertTriangle className="h-10 w-10 text-danger-600" aria-hidden="true" />
      <h3 className="font-display text-lg font-semibold text-ink-900">{title}</h3>
      <p className="max-w-sm text-sm text-ink-700/70">{description}</p>
      {onRetry && (
        <Button variant="outline" onClick={onRetry}>
          Try again
        </Button>
      )}
    </div>
  )
}
