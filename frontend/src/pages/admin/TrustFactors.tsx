import { useState } from 'react'
import { ShieldCheck } from 'lucide-react'
import { useAdminTrustScoreFactors, useUpdateTrustScoreFactor, type AdminTrustScoreFactor } from '../../lib/api/admin'
import { AdminPageHeader } from '../../components/admin/AdminPageHeader'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'

export function TrustFactors() {
  const { data: factors, isPending, isError, refetch } = useAdminTrustScoreFactors()
  const update = useUpdateTrustScoreFactor()

  return (
    <div className="flex flex-col gap-4">
      <AdminPageHeader
        icon={ShieldCheck}
        tone="warning"
        title="Trust score factors"
        description="What counts toward a listing's trust score, and how much. Turning a factor off recomputes on the next trigger — it doesn't retroactively rewrite history."
      />

      {isPending && <PropertyGridSkeleton count={4} />}
      {isError && <ErrorState onRetry={refetch} />}

      <div className="flex flex-col gap-2">
        {factors?.map((factor) => (
          <FactorRow key={factor.id} factor={factor} update={update} />
        ))}
      </div>
    </div>
  )
}

function FactorRow({
  factor,
  update,
}: {
  factor: AdminTrustScoreFactor
  update: ReturnType<typeof useUpdateTrustScoreFactor>
}) {
  const [points, setPoints] = useState(String(factor.max_points))

  const savePoints = () => {
    const value = Number(points)
    if (!value || value === factor.max_points) return
    update.mutate({ id: factor.id, max_points: value })
  }

  return (
    <Card className="flex flex-wrap items-center justify-between gap-3 p-4">
      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-2">
          <p className="text-sm font-medium text-ink-900">{factor.label}</p>
          <Badge tone={factor.is_active ? 'success' : 'neutral'}>{factor.is_active ? 'active' : 'inactive'}</Badge>
        </div>
        <p className="mt-0.5 text-xs text-ink-700/60">{factor.description}</p>
      </div>
      <div className="flex shrink-0 items-center gap-2">
        <label className="flex items-center gap-1.5 text-xs text-ink-700/70">
          Max points
          <input
            type="number"
            min={1}
            max={100}
            value={points}
            onChange={(e) => setPoints(e.target.value)}
            onBlur={savePoints}
            className="h-8 w-16 rounded-md border border-stone-200 px-2 text-sm focus:outline-none focus:ring-2 focus:ring-trust-700"
          />
        </label>
        <Button
          size="sm"
          variant="outline"
          isLoading={update.isPending && update.variables?.id === factor.id}
          onClick={() => update.mutate({ id: factor.id, is_active: !factor.is_active })}
        >
          {factor.is_active ? 'Deactivate' : 'Activate'}
        </Button>
      </div>
    </Card>
  )
}
