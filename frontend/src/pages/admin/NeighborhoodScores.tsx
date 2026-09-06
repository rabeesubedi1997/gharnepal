import { useEffect, useState } from 'react'
import { MapPin, Trash2 } from 'lucide-react'
import {
  NEIGHBORHOOD_SCORE_FACTORS,
  NEIGHBORHOOD_SCORE_FACTOR_LABEL,
  POI_TYPES,
  POI_TYPE_LABEL,
  useAdminAddPoi,
  useAdminDeletePoi,
  useAdminSetNeighborhoodScore,
  useNeighborhoodList,
  useNeighborhoodProfile,
  type NeighborhoodScoreFactorKey,
  type PoiType,
} from '../../lib/api/neighborhoods'
import { getErrorMessage } from '../../lib/api/errors'
import { AdminPageHeader } from '../../components/admin/AdminPageHeader'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { Input, Select } from '../../components/ui/Input'
import { ErrorState } from '../../components/ui/ErrorState'
import { Skeleton } from '../../components/ui/Skeleton'

type FactorState = Record<NeighborhoodScoreFactorKey, { score: number; notes: string }>

function emptyFactors(): FactorState {
  return Object.fromEntries(NEIGHBORHOOD_SCORE_FACTORS.map((key) => [key, { score: 5, notes: '' }])) as FactorState
}

export function NeighborhoodScores() {
  const { data: neighborhoods, isPending: listPending } = useNeighborhoodList()
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const { data: profile, isPending: profilePending, isError, refetch } = useNeighborhoodProfile(selectedId ?? undefined)
  const setScore = useAdminSetNeighborhoodScore()
  const addPoi = useAdminAddPoi()
  const deletePoi = useAdminDeletePoi()

  const [factors, setFactors] = useState<FactorState>(emptyFactors)
  const [saveMessage, setSaveMessage] = useState<string | null>(null)
  const [saveError, setSaveError] = useState<string | null>(null)

  const [poiType, setPoiType] = useState<PoiType>('school')
  const [poiName, setPoiName] = useState('')
  const [poiError, setPoiError] = useState<string | null>(null)

  useEffect(() => {
    if (!neighborhoods || neighborhoods.length === 0 || selectedId !== null) return
    setSelectedId(neighborhoods[0].id)
  }, [neighborhoods, selectedId])

  useEffect(() => {
    setSaveMessage(null)
    setSaveError(null)
    if (profile?.score) {
      const next = emptyFactors()
      for (const f of profile.score.factors) {
        if (f.key in next) {
          next[f.key as NeighborhoodScoreFactorKey] = { score: f.score, notes: f.notes ?? '' }
        }
      }
      setFactors(next)
    } else {
      setFactors(emptyFactors())
    }
  }, [profile?.id, profile?.score]) // eslint-disable-line react-hooks/exhaustive-deps

  const handleSaveScore = () => {
    if (!selectedId) return
    setSaveMessage(null)
    setSaveError(null)
    setScore.mutate(
      {
        neighborhoodId: selectedId,
        factors: NEIGHBORHOOD_SCORE_FACTORS.map((key) => ({ key, score: factors[key].score, notes: factors[key].notes || undefined })),
      },
      {
        onSuccess: () => setSaveMessage('Score saved.'),
        onError: (err) => setSaveError(getErrorMessage(err)),
      },
    )
  }

  const handleAddPoi = () => {
    if (!selectedId || !poiName.trim()) return
    setPoiError(null)
    addPoi.mutate(
      { neighborhoodId: selectedId, poi_type: poiType, name: poiName.trim() },
      { onSuccess: () => setPoiName(''), onError: (err) => setPoiError(getErrorMessage(err)) },
    )
  }

  return (
    <div className="flex flex-col gap-6">
      <AdminPageHeader
        icon={MapPin}
        tone="link"
        title="Neighborhoods"
        description="Curate a livability score and points of interest per neighborhood."
      />
      <div className="max-w-sm">
        <Select
          label="Neighborhood"
          value={selectedId ?? ''}
          onChange={(e) => setSelectedId(Number(e.target.value))}
          disabled={listPending}
        >
          {listPending && <option>Loading…</option>}
          {neighborhoods?.map((n) => (
            <option key={n.id} value={n.id}>
              {n.name} — {n.ward?.municipality ?? 'Unknown city'} {n.is_curated ? '(curated)' : ''}
            </option>
          ))}
        </Select>
      </div>

      {profilePending && <Skeleton className="h-64 w-full" />}
      {isError && <ErrorState onRetry={refetch} />}

      {profile && !profilePending && (
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <Card className="flex flex-col gap-4 p-4">
            <h2 className="font-display text-lg font-semibold text-ink-900">Livability score — {profile.name}</h2>
            <div className="flex flex-col gap-4">
              {NEIGHBORHOOD_SCORE_FACTORS.map((key) => (
                <div key={key} className="flex flex-col gap-1">
                  <div className="flex items-center justify-between text-sm">
                    <label htmlFor={`factor-${key}`} className="font-medium text-ink-900">
                      {NEIGHBORHOOD_SCORE_FACTOR_LABEL[key]}
                    </label>
                    <span className="text-ink-700/60">{factors[key].score}/10</span>
                  </div>
                  <input
                    id={`factor-${key}`}
                    type="range"
                    min={0}
                    max={10}
                    value={factors[key].score}
                    onChange={(e) => setFactors({ ...factors, [key]: { ...factors[key], score: Number(e.target.value) } })}
                    className="w-full accent-trust-700"
                  />
                  <input
                    type="text"
                    value={factors[key].notes}
                    onChange={(e) => setFactors({ ...factors, [key]: { ...factors[key], notes: e.target.value } })}
                    placeholder="Optional note (e.g. why this score)"
                    maxLength={255}
                    className="h-8 rounded-lg border border-stone-200 px-2 text-xs focus:outline-none focus:ring-2 focus:ring-trust-700"
                  />
                </div>
              ))}
            </div>
            {saveError && <p className="text-sm text-danger-600">{saveError}</p>}
            {saveMessage && <p className="text-sm text-success-600">{saveMessage}</p>}
            <Button isLoading={setScore.isPending} onClick={handleSaveScore}>
              Save score
            </Button>
          </Card>

          <Card className="flex flex-col gap-4 p-4">
            <h2 className="font-display text-lg font-semibold text-ink-900">Points of interest</h2>
            <ul className="flex flex-col gap-2">
              {profile.pois.length === 0 && <p className="text-sm text-ink-700/60">No POIs added yet.</p>}
              {profile.pois.map((poi) => (
                <li key={poi.id} className="flex items-center justify-between gap-2 rounded-lg border border-stone-100 px-3 py-2 text-sm">
                  <div className="flex items-center gap-2">
                    <span className="text-ink-900">{poi.name}</span>
                    <Badge tone="neutral">{POI_TYPE_LABEL[poi.poi_type]}</Badge>
                  </div>
                  <button
                    type="button"
                    aria-label={`Remove ${poi.name}`}
                    onClick={() => deletePoi.mutate({ poiId: poi.id, neighborhoodId: profile.id })}
                    className="rounded-md p-1 text-danger-600 hover:bg-danger-100/40"
                  >
                    <Trash2 className="h-4 w-4" aria-hidden="true" />
                  </button>
                </li>
              ))}
            </ul>

            <div className="flex flex-col gap-2 border-t border-stone-100 pt-4">
              <div className="flex gap-2">
                <Select value={poiType} onChange={(e) => setPoiType(e.target.value as PoiType)} className="w-40">
                  {POI_TYPES.map((t) => (
                    <option key={t} value={t}>
                      {POI_TYPE_LABEL[t]}
                    </option>
                  ))}
                </Select>
                <Input placeholder="Name (e.g. Boudha Secondary School)" value={poiName} onChange={(e) => setPoiName(e.target.value)} className="flex-1" />
              </div>
              {poiError && <p className="text-sm text-danger-600">{poiError}</p>}
              <Button variant="outline" size="sm" isLoading={addPoi.isPending} disabled={!poiName.trim()} onClick={handleAddPoi}>
                Add POI
              </Button>
            </div>
          </Card>
        </div>
      )}
    </div>
  )
}
