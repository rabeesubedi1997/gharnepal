import { useState } from 'react'
import { ShieldAlert, ShieldCheck, Users as UsersIcon } from 'lucide-react'
import {
  useAdminUsers,
  useUpdateUserRoles,
  useUpdateUserStatus,
  type AccountStatus,
  type AdminRoleKey,
  type AdminUser,
} from '../../lib/api/admin'
import { useCurrentUser } from '../../lib/api/auth'
import { getErrorMessage } from '../../lib/api/errors'
import { AdminPageHeader } from '../../components/admin/AdminPageHeader'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { Input, Select } from '../../components/ui/Input'
import { Modal } from '../../components/ui/Modal'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'

const ROLE_OPTIONS: { key: AdminRoleKey; label: string }[] = [
  { key: 'buyer', label: 'Buyer' },
  { key: 'owner', label: 'Owner' },
  { key: 'agent', label: 'Agent' },
  { key: 'agency_admin', label: 'Agency admin' },
  { key: 'admin', label: 'Admin' },
]

const STATUS_TONE: Record<AccountStatus, 'success' | 'danger' | 'warning'> = {
  active: 'success',
  suspended: 'danger',
  pending: 'warning',
}

export function Users() {
  const { data: me } = useCurrentUser()
  const [q, setQ] = useState('')
  const [role, setRole] = useState<AdminRoleKey | ''>('')
  const [status, setStatus] = useState<AccountStatus | ''>('')
  const [page, setPage] = useState(1)
  const { data, isPending, isError, refetch } = useAdminUsers({
    q: q || undefined,
    role: role || undefined,
    status: status || undefined,
    page,
  })
  const updateStatus = useUpdateUserStatus()
  const [editingRoles, setEditingRoles] = useState<AdminUser | null>(null)

  return (
    <div className="flex flex-col gap-4">
      <AdminPageHeader
        icon={UsersIcon}
        tone="accent"
        title="Users"
        description="Search, review roles, and suspend accounts when needed."
      />

      <div className="flex flex-wrap gap-3">
        <Input
          placeholder="Search by name or email"
          value={q}
          onChange={(e) => {
            setQ(e.target.value)
            setPage(1)
          }}
          className="max-w-xs"
        />
        <Select
          value={role}
          onChange={(e) => {
            setRole(e.target.value as AdminRoleKey | '')
            setPage(1)
          }}
          className="w-40"
        >
          <option value="">All roles</option>
          {ROLE_OPTIONS.map((r) => (
            <option key={r.key} value={r.key}>
              {r.label}
            </option>
          ))}
        </Select>
        <Select
          value={status}
          onChange={(e) => {
            setStatus(e.target.value as AccountStatus | '')
            setPage(1)
          }}
          className="w-40"
        >
          <option value="">All statuses</option>
          <option value="active">Active</option>
          <option value="suspended">Suspended</option>
          <option value="pending">Pending</option>
        </Select>
      </div>

      {isPending && <PropertyGridSkeleton count={4} />}
      {isError && <ErrorState onRetry={refetch} />}

      {!isPending && !isError && data?.data.length === 0 && (
        <EmptyState title="No users found" description="Try a different search or filter." />
      )}

      <div className="flex flex-col gap-2">
        {data?.data.map((user) => {
          const isSelf = user.id === me?.id
          return (
            <Card key={user.id} className="flex flex-wrap items-center justify-between gap-3 p-4">
              <div className="min-w-0">
                <p className="font-medium text-ink-900">
                  {user.name} {isSelf && <span className="text-xs text-ink-700/50">(you)</span>}
                </p>
                <p className="text-xs text-ink-700/60">{user.email}</p>
                <div className="mt-1 flex flex-wrap gap-1">
                  {user.roles.map((r) => (
                    <Badge key={r} tone="neutral">
                      {ROLE_OPTIONS.find((o) => o.key === r)?.label ?? r}
                    </Badge>
                  ))}
                  {user.agencies.map((a) => (
                    <Badge key={a} tone="trust">
                      {a}
                    </Badge>
                  ))}
                </div>
              </div>
              <div className="flex items-center gap-2">
                <Badge tone={STATUS_TONE[user.status]}>{user.status}</Badge>
                <Button size="sm" variant="outline" onClick={() => setEditingRoles(user)}>
                  Edit roles
                </Button>
                {!isSelf && (
                  <Button
                    size="sm"
                    variant={user.status === 'suspended' ? 'outline' : 'danger'}
                    isLoading={updateStatus.isPending && updateStatus.variables?.userId === user.id}
                    onClick={() =>
                      updateStatus.mutate({ userId: user.id, status: user.status === 'suspended' ? 'active' : 'suspended' })
                    }
                  >
                    {user.status === 'suspended' ? (
                      <>
                        <ShieldCheck className="h-4 w-4" /> Reactivate
                      </>
                    ) : (
                      <>
                        <ShieldAlert className="h-4 w-4" /> Suspend
                      </>
                    )}
                  </Button>
                )}
              </div>
            </Card>
          )
        })}
      </div>

      {data && data.meta.last_page > 1 && (
        <div className="flex items-center justify-center gap-3">
          <Button variant="outline" size="sm" disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>
            Previous
          </Button>
          <span className="text-sm text-ink-700/70">
            Page {data.meta.current_page} of {data.meta.last_page}
          </span>
          <Button variant="outline" size="sm" disabled={page >= data.meta.last_page} onClick={() => setPage((p) => p + 1)}>
            Next
          </Button>
        </div>
      )}

      <EditRolesModal user={editingRoles} onClose={() => setEditingRoles(null)} isSelf={editingRoles?.id === me?.id} />
    </div>
  )
}

function EditRolesModal({ user, onClose, isSelf }: { user: AdminUser | null; onClose: () => void; isSelf: boolean }) {
  const [selected, setSelected] = useState<AdminRoleKey[]>([])
  const [error, setError] = useState<string | null>(null)
  const updateRoles = useUpdateUserRoles()

  if (user && selected.length === 0 && user.roles.length > 0 && !error) {
    // Sync local state on open — cheap enough to do inline given the tiny list.
    if (JSON.stringify(selected) !== JSON.stringify(user.roles)) {
      setSelected(user.roles)
    }
  }

  const toggle = (key: AdminRoleKey) => {
    setSelected((prev) => (prev.includes(key) ? prev.filter((r) => r !== key) : [...prev, key]))
  }

  const handleClose = () => {
    setSelected([])
    setError(null)
    onClose()
  }

  return (
    <Modal open={!!user} onClose={handleClose} title={user ? `Edit roles — ${user.name}` : undefined}>
      {user && (
        <div className="flex flex-col gap-3">
          {isSelf && <p className="text-xs text-ink-700/60">You cannot remove your own admin role.</p>}
          <div className="flex flex-wrap gap-2">
            {ROLE_OPTIONS.map((r) => (
              <button
                key={r.key}
                type="button"
                onClick={() => toggle(r.key)}
                className={
                  selected.includes(r.key)
                    ? 'rounded-full bg-trust-700 px-3 py-1.5 text-xs font-medium text-white'
                    : 'rounded-full border border-stone-200 bg-white px-3 py-1.5 text-xs font-medium text-ink-700 hover:bg-stone-100'
                }
              >
                {r.label}
              </button>
            ))}
          </div>
          {error && <p className="text-sm text-danger-600">{error}</p>}
          <Button
            isLoading={updateRoles.isPending}
            disabled={selected.length === 0}
            onClick={() =>
              updateRoles.mutate(
                { userId: user.id, roles: selected },
                { onSuccess: handleClose, onError: (e) => setError(getErrorMessage(e)) },
              )
            }
          >
            Save roles
          </Button>
        </div>
      )}
    </Modal>
  )
}
