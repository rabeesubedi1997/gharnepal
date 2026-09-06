import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { MapPin, MessageSquareText, ShieldCheck } from 'lucide-react'
import {
  COMMUNITY_NOTE_CATEGORIES,
  COMMUNITY_NOTE_CATEGORY_LABEL,
  NEIGHBORHOOD_SCORE_FACTOR_LABEL,
  POI_TYPE_LABEL,
  useNeighborhoodProfile,
  useSubmitCommunityNote,
  type CommunityNoteCategory,
} from '../../lib/api/neighborhoods'
import { useCurrentUser } from '../../lib/api/auth'
import { getErrorMessage } from '../../lib/api/errors'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { Select } from '../../components/ui/Input'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { Skeleton } from '../../components/ui/Skeleton'

function ScoreBar({ label, score, notes }: { label: string; score: number; notes: string | null }) {
  return (
    <div className="flex flex-col gap-1">
      <div className="flex items-center justify-between text-sm">
        <span className="font-medium text-ink-900">{label}</span>
        <span className="text-ink-700/60">{score}/10</span>
      </div>
      <div className="h-2 w-full overflow-hidden rounded-full bg-stone-100">
        <div className="h-full rounded-full bg-trust-700" style={{ width: `${score * 10}%` }} />
      </div>
      {notes && <p className="text-xs text-ink-700/60">{notes}</p>}
    </div>
  )
}

export function NeighborhoodProfile() {
  const { id } = useParams<{ id: string }>()
  const { data: neighborhood, isPending, isError, refetch } = useNeighborhoodProfile(id)
  const { data: user } = useCurrentUser()
  const submitNote = useSubmitCommunityNote()

  const [category, setCategory] = useState<CommunityNoteCategory>('other')
  const [body, setBody] = useState('')
  const [formError, setFormError] = useState<string | null>(null)
  const [submitted, setSubmitted] = useState(false)

  if (isPending) {
    return (
      <div className="flex flex-col gap-4">
        <Skeleton className="h-8 w-64" />
        <Skeleton className="h-40 w-full" />
      </div>
    )
  }

  if (isError || !neighborhood) {
    return <ErrorState onRetry={refetch} description="Couldn't load this neighborhood right now." />
  }

  const handleSubmitNote = (e: React.FormEvent) => {
    e.preventDefault()
    setFormError(null)
    if (body.trim().length === 0) {
      setFormError('Please describe what you know about this neighborhood.')
      return
    }
    submitNote.mutate(
      { neighborhoodId: neighborhood.id, category, body: body.trim() },
      {
        onSuccess: () => {
          setBody('')
          setSubmitted(true)
        },
        onError: (err) => setFormError(getErrorMessage(err)),
      },
    )
  }

  return (
    <div className="flex flex-col gap-6">
      <div>
        <Link to="/neighborhoods" className="text-sm text-link-600 hover:text-link-700">
          &larr; All neighborhoods
        </Link>
        <div className="mt-2 flex flex-wrap items-center justify-between gap-2">
          <div>
            <h1 className="font-display text-2xl font-semibold text-ink-900">{neighborhood.name}</h1>
            <p className="flex items-center gap-1 text-sm text-ink-700/60">
              <MapPin className="h-4 w-4" aria-hidden="true" />
              {neighborhood.ward?.municipality ?? 'Unknown city'}
            </p>
          </div>
          {neighborhood.score && (
            <span className="inline-flex items-center gap-1.5 rounded-full bg-trust-100 px-3 py-1.5 text-sm font-semibold text-trust-700">
              {neighborhood.score.overall_score}/10 livability
            </span>
          )}
        </div>
        {neighborhood.is_curated ? (
          <Badge tone="trust">
            <ShieldCheck className="h-3 w-3" aria-hidden="true" /> Admin-curated
          </Badge>
        ) : (
          <Badge tone="neutral">Not yet curated — scores coming soon</Badge>
        )}
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div className="flex flex-col gap-6 lg:col-span-2">
          <Card className="flex flex-col gap-4 p-4">
            <h2 className="font-display text-lg font-semibold text-ink-900">Livability factors</h2>
            {neighborhood.score && neighborhood.score.factors.length > 0 ? (
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                {neighborhood.score.factors.map((f) => (
                  <ScoreBar
                    key={f.key}
                    label={NEIGHBORHOOD_SCORE_FACTOR_LABEL[f.key as keyof typeof NEIGHBORHOOD_SCORE_FACTOR_LABEL] ?? f.key}
                    score={f.score}
                    notes={f.notes}
                  />
                ))}
              </div>
            ) : (
              <EmptyState title="No score yet" description="An admin hasn't curated livability factors for this neighborhood yet." />
            )}
          </Card>

          <Card className="flex flex-col gap-4 p-4">
            <h2 className="font-display text-lg font-semibold text-ink-900">Places nearby</h2>
            {neighborhood.pois.length === 0 ? (
              <EmptyState title="No points of interest yet" description="Schools, hospitals, and markets will appear here once curated." />
            ) : (
              <ul className="grid grid-cols-1 gap-2 sm:grid-cols-2">
                {neighborhood.pois.map((poi) => (
                  <li key={poi.id} className="flex items-center justify-between gap-2 rounded-lg border border-stone-100 px-3 py-2 text-sm">
                    <span className="text-ink-900">{poi.name}</span>
                    <Badge tone="neutral">{POI_TYPE_LABEL[poi.poi_type]}</Badge>
                  </li>
                ))}
              </ul>
            )}
          </Card>
        </div>

        <Card className="flex flex-col gap-4 p-4">
          <div className="flex items-center gap-2">
            <MessageSquareText className="h-5 w-5 text-trust-700" aria-hidden="true" />
            <h2 className="font-display text-lg font-semibold text-ink-900">Community knowledge</h2>
          </div>
          <p className="text-xs text-ink-700/60">
            Real notes from verified residents — water supply, power cuts, road conditions. Every note is reviewed
            by an admin before it goes public.
          </p>

          {neighborhood.community_notes.length === 0 ? (
            <EmptyState title="No approved notes yet" description="Be the first to share something useful about this area." />
          ) : (
            <ul className="flex flex-col gap-3">
              {neighborhood.community_notes.map((note) => (
                <li key={note.id} className="rounded-lg border border-stone-100 p-3">
                  <div className="mb-1 flex items-center justify-between gap-2">
                    <Badge tone="neutral">{COMMUNITY_NOTE_CATEGORY_LABEL[note.category]}</Badge>
                    <span className="text-xs text-ink-700/50">{new Date(note.created_at).toLocaleDateString()}</span>
                  </div>
                  <p className="text-sm text-ink-700/80">{note.body}</p>
                </li>
              ))}
            </ul>
          )}

          <div className="border-t border-stone-100 pt-4">
            {!user && (
              <p className="text-sm text-ink-700/70">
                <Link to="/login" className="text-link-600 hover:text-link-700">
                  Log in
                </Link>{' '}
                to contribute what you know about this neighborhood.
              </p>
            )}
            {user && !user.phone_verified && (
              <p className="text-sm text-ink-700/70">
                <Link to="/account/verification" className="text-link-600 hover:text-link-700">
                  Verify your phone number
                </Link>{' '}
                to contribute neighborhood notes.
              </p>
            )}
            {user && user.phone_verified && !submitted && (
              <form onSubmit={handleSubmitNote} className="flex flex-col gap-3">
                <Select label="Category" value={category} onChange={(e) => setCategory(e.target.value as CommunityNoteCategory)}>
                  {COMMUNITY_NOTE_CATEGORIES.map((c) => (
                    <option key={c} value={c}>
                      {COMMUNITY_NOTE_CATEGORY_LABEL[c]}
                    </option>
                  ))}
                </Select>
                <div className="flex flex-col gap-1.5">
                  <label htmlFor="note-body" className="text-sm font-medium text-ink-900">
                    What should buyers/renters know?
                  </label>
                  <textarea
                    id="note-body"
                    rows={4}
                    maxLength={500}
                    value={body}
                    onChange={(e) => setBody(e.target.value)}
                    placeholder="e.g. Water supply is irregular during the dry season here."
                    className="rounded-lg border border-stone-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-trust-700"
                  />
                  <p className="text-right text-xs text-ink-700/50">{body.length}/500</p>
                </div>
                {formError && <p className="text-sm text-danger-600">{formError}</p>}
                <Button type="submit" isLoading={submitNote.isPending}>
                  Submit for review
                </Button>
              </form>
            )}
            {submitted && (
              <p className="text-sm text-success-600">
                Thanks — your note is pending admin review and will appear here once approved.
              </p>
            )}
          </div>
        </Card>
      </div>
    </div>
  )
}
