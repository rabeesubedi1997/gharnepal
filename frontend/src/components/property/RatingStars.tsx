import { Star } from 'lucide-react'
import { clsx } from 'clsx'

/** Read-only star display — used on cards and the listing detail header. */
export function RatingStars({
  average,
  count,
  size = 'sm',
}: {
  average: number | null
  count: number
  size?: 'sm' | 'md'
}) {
  if (count === 0 || average === null) {
    return <span className="text-xs text-ink-700/50">No ratings yet</span>
  }

  const starClass = size === 'md' ? 'h-4 w-4' : 'h-3.5 w-3.5'

  return (
    <span className="inline-flex items-center gap-1">
      <span className="flex items-center">
        {[1, 2, 3, 4, 5].map((n) => (
          <Star
            key={n}
            className={clsx(starClass, n <= Math.round(average) ? 'fill-warning-600 text-warning-600' : 'text-stone-300')}
            aria-hidden="true"
          />
        ))}
      </span>
      <span className="text-xs text-ink-700/60">
        {average.toFixed(1)} ({count})
      </span>
    </span>
  )
}
