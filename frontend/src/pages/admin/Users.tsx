import { useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { ShieldAlert, ShieldCheck, UserPlus, Users as UsersIcon } from 'lucide-react'
import {
  useAdminUsers,
  useCreateAdminUser,
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

const ROLE_OPTIONS: { key: AdminRoleKey; label: string; privileged?: boolean }[] = [
  { key: 'buyer', label: 'Buyer' },
  { key: 'owner', label: 'Owner' },
  { key: 'agent', label: 'Agent' },
  { key: 'agency_admin', label: 'Agency admin' },
  { key: 'admin', label: 'Admin', privileged: true },
  { key: 'super_admin', label: 'Super admin', privileged: true },
]
const PRIVILEGED_KEYS = ROLE_OPTIONS.filter((r) => r.privileged).map((r) => r.key)

const STATUS_TONE: Record<AccountStatus, 'success' | 'danger' | 'warning'> = {
  active: 'success',
  suspended: 'danger',
  pending: 'warning',
}

export function Users() {
  const { data: me } = useCurrentUser()
  const [searchParams, setSearchParams] = useSearchParams()
  const [q, setQ] = useState('')
  const [role, setRole] = useState<AdminRoleKey | ''>((searchParams.get('role') as AdminRoleKey) ?? '')
  const [status, setStatus] = useState<AccountStatus | ''>((searchParams.get('status') as AccountStatus) ?? '')
  const [page, setPage] = useState(1)
  const [createOpen, setCreateOpen] = useState(false)
  const { data, isPending, isError, refetch } = useAdminUsers({
    q: q || undefined,
    role: role || undefined,
    status: status || undefined,
    page,
  })
  const updateStatus = useUpdateUserStatus()
  const [editingRoles, setEditingRoles] = useState<AdminUser | null>(null)

  const changeRole = (value: AdminRoleKey | '') => {
    setRole(value)
    setPage(1)
    setSearchParams((prev) => {
      const next = new URLSearchParams(prev)
      if (value) next.set('role', value)
      else next.delete('role')
      return next
    })
  }

  const changeStatus = (value: AccountStatus | '') => {
    setStatus(value)
    setPage(1)
    setSearchParams((prev) => {
      const next = new URLSearchParams(prev)
      if (value) next.set('status', value)
      else next.delete('status')
      return next
    })
  }

  return (
    <div className="flex flex-col gap-4">
      <AdminPageHeader
        icon={UsersIcon}
        tone="trust"
        title="Users"
        description="Search, review roles, and suspend accounts when needed."
        action={
          <Button size="sm" onClick={() => setCreateOpen(true)}>
            <UserPlus className="h-4 w-4" /> New user
          </Button>
        }
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
        <Select value={role} onChange={(e) => changeRole(e.target.value as AdminRoleKey | '')} className="w-40">
          <option value="">All roles</option>
          {ROLE_OPTIONS.map((r) => (
            <option key={r.key} value={r.key}>
              {r.label}
            </option>
          ))}
        </Select>
        <Select value={status} onChange={(e) => changeStatus(e.target.value as AccountStatus | '')} className="w-40">
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
                    <Badge key={r} tone={PRIVILEGED_KEYS.includes(r) ? 'trust' : 'neutral'}>
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

      <EditRolesModal
        user={editingRoles}
        onClose={() => setEditingRoles(null)}
        isSelf={editingRoles?.id === me?.id}
        canManagePrivilegedRoles={!!me?.is_super_admin}
      />
      <CreateUserModal open={createOpen} onClose={() => setCreateOpen(false)} canGrantPrivilegedRoles={!!me?.is_super_admin} />
    </div>
  )
}

function EditRolesModal({
  user,
  onClose,
  isSelf,
  canManagePrivilegedRoles,
}: {
  user: AdminUser | null
  onClose: () => void
  isSelf: boolean
  canManagePrivilegedRoles: boolean
}) {
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

  // A regular admin can't see/toggle Admin or Super admin at all — the
  // server rejects any attempt to change them anyway, but hiding them here
  // (rather than showing a disabled control) avoids a confusing "why did
  // saving fail?" the first time someone tries. Whatever privileged roles
  // the target already has are preserved untouched on save either way.
  const visibleOptions = canManagePrivilegedRoles ? ROLE_OPTIONS : ROLE_OPTIONS.filter((r) => !r.privileged)
  const preservedPrivileged = canManagePrivilegedRoles ? [] : (user?.roles.filter((r) => PRIVILEGED_KEYS.includes(r)) ?? [])

  return (
    <Modal open={!!user} onClose={handleClose} title={user ? `Edit roles — ${user.name}` : undefined}>
      {user && (
        <div className="flex flex-col gap-3">
          {isSelf && <p className="text-xs text-ink-700/60">You cannot remove your own admin access.</p>}
          {!canManagePrivilegedRoles && preservedPrivileged.length > 0 && (
            <p className="text-xs text-ink-700/60">
              This user has admin access ({preservedPrivileged.map((r) => ROLE_OPTIONS.find((o) => o.key === r)?.label).join(', ')})
              — only a super admin can change that.
            </p>
          )}
          <div className="flex flex-wrap gap-2">
            {visibleOptions.map((r) => (
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
            disabled={selected.length === 0 && preservedPrivileged.length === 0}
            onClick={() =>
              updateRoles.mutate(
                { userId: user.id, roles: [...new Set([...selected, ...preservedPrivileged])] },
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

function CreateUserModal({
  open,
  onClose,
  canGrantPrivilegedRoles,
}: {
  open: boolean
  onClose: () => void
  canGrantPrivilegedRoles: boolean
}) {
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [roles, setRoles] = useState<AdminRoleKey[]>([])
  const [error, setError] = useState<string | null>(null)
  const create = useCreateAdminUser()

  const visibleOptions = canGrantPrivilegedRoles ? ROLE_OPTIONS : ROLE_OPTIONS.filter((r) => !r.privileged)

  const toggle = (key: AdminRoleKey) => {
    setRoles((prev) => (prev.includes(key) ? prev.filter((r) => r !== key) : [...prev, key]))
  }

  const reset = () => {
    setName('')
    setEmail('')
    setPassword('')
    setRoles([])
    setError(null)
  }

  const handleClose = () => {
    reset()
    onClose()
  }

  return (
    <Modal open={open} onClose={handleClose} title="Create a new user">
      <div className="flex flex-col gap-3">
        <p className="text-xs text-ink-700/60">
          The account is active immediately — no confirmation email is sent. Share the password with them directly.
        </p>
        <Input label="Full name" value={name} onChange={(e) => setName(e.target.value)} />
        <Input label="Email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
        <Input label="Temporary password" type="text" value={password} onChange={(e) => setPassword(e.target.value)} />

        <div>
          <p className="mb-2 text-sm font-medium text-ink-900">Roles</p>
          <div className="flex flex-wrap gap-2">
            {visibleOptions.map((r) => (
              <button
                key={r.key}
                type="button"
                onClick={() => toggle(r.key)}
                className={
                  roles.includes(r.key)
                    ? 'rounded-full bg-trust-700 px-3 py-1.5 text-xs font-medium text-white'
                    : 'rounded-full border border-stone-200 bg-white px-3 py-1.5 text-xs font-medium text-ink-700 hover:bg-stone-100'
                }
              >
                {r.label}
              </button>
            ))}
          </div>
        </div>

        {error && <p className="text-sm text-danger-600">{error}</p>}
        <Button
          isLoading={create.isPending}
          disabled={!name.trim() || !email.trim() || password.length < 8 || roles.length === 0}
          onClick={() =>
            create.mutate(
              { name: name.trim(), email: email.trim(), password, roles },
              { onSuccess: handleClose, onError: (e) => setError(getErrorMessage(e)) },
            )
          }
        >
          Create user
        </Button>
      </div>
    </Modal>
  )
}
