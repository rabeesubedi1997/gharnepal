import { useState } from 'react'
import { CreditCard, Trash2 } from 'lucide-react'
import {
  useAdminPaymentGateways,
  useCreateGateway,
  useDeleteGateway,
  useGatewayCatalog,
  useUpdateGateway,
  type AdminPaymentGateway,
  type GatewayCredentialField,
} from '../../lib/api/adminPaymentGateways'
import { getErrorMessage } from '../../lib/api/errors'
import { AdminPageHeader } from '../../components/admin/AdminPageHeader'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { Input, Select } from '../../components/ui/Input'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'

function CredentialFields({
  fields,
  values,
  onChange,
}: {
  fields: GatewayCredentialField[]
  values: Record<string, string>
  onChange: (key: string, value: string) => void
  existing?: Record<string, { value: string | null; configured: boolean }>
}) {
  if (fields.length === 0) return null

  return (
    <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
      {fields.map((field) => (
        <Input
          key={field.key}
          label={field.label}
          type={field.type === 'password' ? 'password' : 'text'}
          value={values[field.key] ?? ''}
          onChange={(e) => onChange(field.key, e.target.value)}
        />
      ))}
    </div>
  )
}

function AddGatewayForm() {
  const { data: catalog } = useGatewayCatalog()
  const create = useCreateGateway()

  const [provider, setProvider] = useState('')
  const [label, setLabel] = useState('')
  const [isSandbox, setIsSandbox] = useState(true)
  const [instructions, setInstructions] = useState('')
  const [credentials, setCredentials] = useState<Record<string, string>>({})
  const [error, setError] = useState<string | null>(null)

  const schema = catalog?.find((c) => c.provider === provider)

  const handleCreate = () => {
    if (!provider || !label.trim()) return
    setError(null)
    create.mutate(
      {
        provider,
        label: label.trim(),
        is_sandbox: isSandbox,
        instructions: provider === 'manual' ? instructions.trim() : undefined,
        credentials,
      },
      {
        onSuccess: () => {
          setProvider('')
          setLabel('')
          setIsSandbox(true)
          setInstructions('')
          setCredentials({})
        },
        onError: (e) => setError(getErrorMessage(e)),
      },
    )
  }

  return (
    <Card className="flex flex-col gap-3 p-4">
      <h2 className="font-display text-base font-semibold text-ink-900">Add a payment method</h2>
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
        <Select
          label="Provider"
          value={provider}
          onChange={(e) => {
            setProvider(e.target.value)
            setCredentials({})
          }}
        >
          <option value="">Choose a provider…</option>
          {catalog?.map((c) => (
            <option key={c.provider} value={c.provider}>
              {c.label}
            </option>
          ))}
        </Select>
        <Input
          label="Name for this account"
          placeholder="e.g. eSewa — main account"
          value={label}
          onChange={(e) => setLabel(e.target.value)}
        />
      </div>

      {provider && provider !== 'manual' && provider !== 'sandbox' && (
        <label className="flex items-center gap-2 text-sm text-ink-900">
          <input type="checkbox" checked={isSandbox} onChange={(e) => setIsSandbox(e.target.checked)} className="h-4 w-4 rounded border-stone-300 text-trust-700" />
          Sandbox / test mode (uncheck once you're ready to take real payments)
        </label>
      )}

      {provider === 'manual' && (
        <Input
          label="Instructions shown to the buyer"
          placeholder="e.g. Transfer to Global IME Bank, account 01234567, then send us the receipt on WhatsApp."
          value={instructions}
          onChange={(e) => setInstructions(e.target.value)}
        />
      )}

      {schema && <CredentialFields fields={schema.fields} values={credentials} onChange={(k, v) => setCredentials((c) => ({ ...c, [k]: v }))} />}

      {error && <p className="text-sm text-danger-600">{error}</p>}
      <Button className="self-start" size="sm" isLoading={create.isPending} disabled={!provider || !label.trim()} onClick={handleCreate}>
        Add
      </Button>
    </Card>
  )
}

function GatewayCard({ config, schema }: { config: AdminPaymentGateway; schema?: GatewayCredentialField[] }) {
  const update = useUpdateGateway()
  const remove = useDeleteGateway()
  const [editing, setEditing] = useState(false)
  const [label, setLabel] = useState(config.label)
  const [instructions, setInstructions] = useState(config.instructions ?? '')
  const [credentials, setCredentials] = useState<Record<string, string>>({})
  const [error, setError] = useState<string | null>(null)

  const handleSave = () => {
    setError(null)
    update.mutate(
      { id: config.id, label: label.trim(), instructions: instructions.trim() || undefined, credentials },
      {
        onSuccess: () => {
          setEditing(false)
          setCredentials({})
        },
        onError: (e) => setError(getErrorMessage(e)),
      },
    )
  }

  return (
    <Card className="flex flex-col gap-3 p-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex items-center gap-2">
          <p className="font-medium text-ink-900">{config.label}</p>
          <Badge tone="neutral">{config.provider}</Badge>
          {config.is_sandbox && <Badge tone="warning">sandbox</Badge>}
        </div>
        <div className="flex items-center gap-2">
          <label className="flex items-center gap-1.5 text-xs font-medium text-ink-700">
            <input
              type="checkbox"
              checked={config.is_enabled}
              onChange={(e) => update.mutate({ id: config.id, is_enabled: e.target.checked })}
              className="h-4 w-4 rounded border-stone-300 text-trust-700"
            />
            Enabled
          </label>
          <button type="button" onClick={() => setEditing((v) => !v)} className="text-xs font-medium text-link-600 hover:text-link-700">
            {editing ? 'Cancel' : 'Edit'}
          </button>
          <button
            type="button"
            aria-label="Delete"
            onClick={() => remove.mutate(config.id)}
            className="rounded-md p-1 text-danger-600 hover:bg-danger-100/40"
          >
            <Trash2 className="h-4 w-4" />
          </button>
        </div>
      </div>

      {!editing && config.provider !== 'sandbox' && (
        <p className="text-xs text-ink-700/60">
          {(schema ?? []).map((f) => `${f.label}: ${config.credentials[f.key]?.configured ? (f.type === 'text' ? config.credentials[f.key]?.value : 'set') : 'not set'}`).join(' · ') || '—'}
        </p>
      )}

      {editing && (
        <div className="flex flex-col gap-3 border-t border-stone-100 pt-3">
          <Input label="Name for this account" value={label} onChange={(e) => setLabel(e.target.value)} />
          {config.provider === 'manual' && (
            <Input label="Instructions shown to the buyer" value={instructions} onChange={(e) => setInstructions(e.target.value)} />
          )}
          {schema && schema.length > 0 && (
            <>
              <p className="text-xs text-ink-700/60">Leave a field blank to keep its current value.</p>
              <CredentialFields fields={schema} values={credentials} onChange={(k, v) => setCredentials((c) => ({ ...c, [k]: v }))} />
            </>
          )}
          {error && <p className="text-sm text-danger-600">{error}</p>}
          <Button size="sm" className="self-start" isLoading={update.isPending} onClick={handleSave}>
            Save
          </Button>
        </div>
      )}
    </Card>
  )
}

export function PaymentGateways() {
  const { data: catalog } = useGatewayCatalog()
  const { data: configs, isPending, isError, refetch } = useAdminPaymentGateways()

  return (
    <div className="flex flex-col gap-6">
      <AdminPageHeader
        icon={CreditCard}
        title="Payment gateways"
        description="Every way buyers can pay for a listing boost — eSewa, Khalti, IME Pay, PayPal, manual bank transfer, or the test sandbox. Add as many merchant accounts as you need; enabled ones appear at checkout immediately."
      />

      <AddGatewayForm />

      {isPending && <PropertyGridSkeleton count={2} />}
      {isError && <ErrorState onRetry={refetch} />}

      <div className="flex flex-col gap-3">
        {configs?.map((config) => (
          <GatewayCard key={config.id} config={config} schema={catalog?.find((c) => c.provider === config.provider)?.fields} />
        ))}
      </div>
    </div>
  )
}
