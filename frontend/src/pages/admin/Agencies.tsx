import { useState } from 'react'
import { Building2, ShieldCheck } from 'lucide-react'
import { useAdminAgencies, useSuspendAgency, useVerifyAgency, type AdminAgency } from '../../lib/api/admin'
import { AdminPageHeader } from '../../components/admin/AdminPageHeader'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { Select } from '../../components/ui/Input'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'

const STATUS_TONE: Record<AdminAgency['status'], 'success' | 'danger' | 'warning'> = {
  active: 'success',
  suspended: 'danger',
  pending: 'warning',
}

export function Agencies() {
  const [status, setStatus] = useState<AdminAgency['status'] | ''>('')
  const { data, isPending, isError, refetch } = useAdminAgencies(status || undefined)
  const verify = useVerifyAgency()
  const suspend = useSuspendAgency()

  return (
    <div className="flex flex-col gap-4">
      <AdminPageHeader
        icon={Building2}
        tone="trust"
        title="Agencies"
        description="Verify new agency registrations, or suspend one that breaks trust."
        action={
          <Select value={status} onChange={(e) => setStatus(e.target.value as AdminAgency['status'] | '')} className="w-44">
            <option value="">All statuses</option>
            <option value="pending">Pending review</option>
            <option value="active">Active</option>
            <option value="suspended">Suspended</option>
          </Select>
        }
      />

      {isPending && <PropertyGridSkeleton count={4} />}
      {isError && <ErrorState onRetry={refetch} />}

      {!isPending && !isError && data?.data.length === 0 && (
        <EmptyState title="No agencies" description="Agency registrations will show up here." />
      )}

      <div className="flex flex-col gap-2">
        {data?.data.map((agency) => (
          <Card key={agency.id} className="flex flex-wrap items-center justify-between gap-3 p-4">
            <div className="flex items-center gap-3">
              {agency.logo_url ? (
                <img src={agency.logo_url} alt="" className="h-10 w-10 rounded-full object-cover" />
              ) : (
                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-trust-100 text-trust-700">
                  <Building2 className="h-5 w-5" aria-hidden="true" />
                </div>
              )}
              <div>
                <p className="font-medium text-ink-900">{agency.name}</p>
                <p className="text-xs text-ink-700/60">{agency.member_count} member(s) · registered {new Date(agency.created_at).toLocaleDateString()}</p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <Badge tone={STATUS_TONE[agency.status]}>{agency.status}</Badge>
              {!agency.is_verified && (
                <Button size="sm" isLoading={verify.isPending && verify.variables === agency.id} onClick={() => verify.mutate(agency.id)}>
                  <ShieldCheck className="h-4 w-4" /> Verify
                </Button>
              )}
              {agency.status !== 'suspended' && (
                <Button
                  size="sm"
                  variant="danger"
                  isLoading={suspend.isPending && suspend.variables === agency.id}
                  onClick={() => suspend.mutate(agency.id)}
                >
                  Suspend
                </Button>
              )}
            </div>
          </Card>
        ))}
      </div>
    </div>
  )
}
