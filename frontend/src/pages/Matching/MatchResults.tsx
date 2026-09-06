import { useState } from 'react'
import { Link } from 'react-router-dom'
import { ChevronDown, ChevronUp, RefreshCw, Sparkles } from 'lucide-react'
import { useMatchPreferences, useMatchResults, useRefreshMatchResults } from '../../lib/api/matching'
import { PropertyCard } from '../../components/property/PropertyCard'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'

export function MatchResults() {
  const { data: prefs, isPending: prefsPending } = useMatchPreferences()
  const { data: results, isPending, isError, refetch } = useMatchResults()
  const refresh = useRefreshMatchResults()
  const [expanded, setExpanded] = useState<number | null>(null)

  const hasPreferences = !!prefs?.id

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-2">
          <Sparkles className="h-6 w-6 text-trust-700" aria-hidden="true" />
          <h1 className="font-display text-2xl font-semibold text-ink-900">Your Smart Matches</h1>
        </div>
        <div className="flex gap-2">
          <Link to="/account/match-preferences">
            <Button variant="outline" size="sm">
              Edit preferences
            </Button>
          </Link>
          {hasPreferences && (
            <Button size="sm" variant="secondary" isLoading={refresh.isPending} onClick={() => refresh.mutate()}>
              <RefreshCw className="h-4 w-4" /> Refresh
            </Button>
          )}
        </div>
      </div>

      {!prefsPending && !hasPreferences && (
        <EmptyState
          title="Set your preferences to get matches"
          description="Budget, bedrooms, commute, must-haves — every preference you set becomes a scored, explained factor."
          action={
            <Link to="/account/match-preferences">
              <Button>Set preferences</Button>
            </Link>
          }
        />
      )}

      {hasPreferences && isPending && <PropertyGridSkeleton count={6} />}
      {hasPreferences && isError && <ErrorState onRetry={refetch} />}

      {hasPreferences && !isPending && !isError && results?.length === 0 && (
        <EmptyState
          title="No matches yet"
          description="No published listings scored above zero against your current preferences. Try widening your budget or dropping a must-have."
          action={
            <Link to="/account/match-preferences">
              <Button variant="outline">Adjust preferences</Button>
            </Link>
          }
        />
      )}

      {hasPreferences && !isPending && !isError && results && results.length > 0 && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {results.map((result) => (
            <div key={result.id} className="flex flex-col gap-2">
              <div className="relative">
                <PropertyCard listing={result.listing} />
                <span className="absolute right-2 top-2 rounded-full bg-trust-700 px-2.5 py-1 text-xs font-bold text-white shadow">
                  {result.score}% match
                </span>
              </div>
              <button
                type="button"
                onClick={() => setExpanded(expanded === result.id ? null : result.id)}
                className="flex items-center justify-center gap-1 rounded-lg border border-stone-200 bg-white px-3 py-1.5 text-xs font-medium text-ink-700 hover:bg-stone-100"
              >
                Why this match? {expanded === result.id ? <ChevronUp className="h-3.5 w-3.5" /> : <ChevronDown className="h-3.5 w-3.5" />}
              </button>
              {expanded === result.id && (
                <ul className="flex flex-col gap-1.5 rounded-lg border border-stone-100 bg-white p-3">
                  {result.reasons.map((reason, i) => (
                    <li key={i} className="text-xs">
                      <div className="flex items-center justify-between">
                        <span className="font-medium text-ink-900">{reason.label}</span>
                        <span className="text-ink-700/60">
                          {reason.points}/{reason.max_points}
                        </span>
                      </div>
                      <p className="text-ink-700/60">{reason.explanation}</p>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
