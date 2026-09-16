import { useState } from 'react'
import { Sparkles, Trash2 } from 'lucide-react'
import {
  useAdminAiProviders,
  useAiProviderCatalog,
  useCreateAiProvider,
  useDeleteAiProvider,
  useUpdateAiProvider,
  type AdminAiProviderConfig,
  type AiProviderCredentialField,
} from '../../lib/api/adminAiProviders'
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
  fields: AiProviderCredentialField[]
  values: Record<string, string>
  onChange: (key: string, value: string) => void
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

function AddProviderForm({ existing }: { existing: AdminAiProviderConfig[] }) {
  const { data: catalog } = useAiProviderCatalog()
  const create = useCreateAiProvider()

  const [provider, setProvider] = useState('')
  const [label, setLabel] = useState('')
  const [credentials, setCredentials] = useState<Record<string, string>>({})
  const [error, setError] = useState<string | null>(null)

  const schema = catalog?.find((c) => c.provider === provider)
  // Only one config per provider (unique DB column) — hide it from the picker once added.
  const availableCatalog = catalog?.filter((c) => !existing.some((e) => e.provider === c.provider))

  const handleCreate = () => {
    if (!provider || !label.trim()) return
    setError(null)
    create.mutate(
      { provider, label: label.trim(), credentials },
      {
        onSuccess: () => {
          setProvider('')
          setLabel('')
          setCredentials({})
        },
        onError: (e) => setError(getErrorMessage(e)),
      },
    )
  }

  if (availableCatalog && availableCatalog.length === 0) return null

  return (
    <Card className="flex flex-col gap-3 p-4">
      <h2 className="font-display text-base font-semibold text-ink-900">Add an AI provider</h2>
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
          {availableCatalog?.map((c) => (
            <option key={c.provider} value={c.provider}>
              {c.label}
            </option>
          ))}
        </Select>
        <Input label="Name" placeholder="e.g. Claude — production key" value={label} onChange={(e) => setLabel(e.target.value)} />
      </div>

      {schema && <CredentialFields fields={schema.fields} values={credentials} onChange={(k, v) => setCredentials((c) => ({ ...c, [k]: v }))} />}

      {error && <p className="text-sm text-danger-600">{error}</p>}
      <Button className="self-start" size="sm" isLoading={create.isPending} disabled={!provider || !label.trim()} onClick={handleCreate}>
        Add
      </Button>
    </Card>
  )
}

function ProviderCard({ config, schema }: { config: AdminAiProviderConfig; schema?: AiProviderCredentialField[] }) {
  const update = useUpdateAiProvider()
  const remove = useDeleteAiProvider()
  const [editing, setEditing] = useState(false)
  const [label, setLabel] = useState(config.label)
  const [credentials, setCredentials] = useState<Record<string, string>>({})
  const [error, setError] = useState<string | null>(null)

  const handleSave = () => {
    setError(null)
    update.mutate(
      { id: config.id, label: label.trim(), credentials },
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
          {config.is_enabled && <Badge tone="success">active</Badge>}
        </div>
        <div className="flex items-center gap-2">
          <label className="flex items-center gap-1.5 text-xs font-medium text-ink-700">
            <input
              type="checkbox"
              checked={config.is_enabled}
              onChange={(e) => update.mutate({ id: config.id, is_enabled: e.target.checked })}
              className="h-4 w-4 rounded border-stone-300 text-trust-700"
            />
            Active
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

      {!editing && (
        <p className="text-xs text-ink-700/60">
          {(schema ?? []).map((f) => `${f.label}: ${config.credentials[f.key]?.configured ? (f.type === 'text' ? config.credentials[f.key]?.value : 'set') : 'not set'}`).join(' · ') || '—'}
        </p>
      )}

      {editing && (
        <div className="flex flex-col gap-3 border-t border-stone-100 pt-3">
          <Input label="Name" value={label} onChange={(e) => setLabel(e.target.value)} />
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

export function AiAssistantSettings() {
  const { data: catalog } = useAiProviderCatalog()
  const { data: configs, isPending, isError, refetch } = useAdminAiProviders()

  return (
    <div className="flex flex-col gap-6">
      <AdminPageHeader
        icon={Sparkles}
        title="AI assistant"
        description="The property-search assistant runs on a free, built-in search engine by default — no API key needed, no cost. Add a Claude or OpenAI key here and mark it Active to upgrade it to a genuinely open-ended conversation instead. Only one provider can be active at a time; turning one on turns any other off. Leave everything below empty to keep the free default."
      />

      {configs && <AddProviderForm existing={configs} />}

      {isPending && <PropertyGridSkeleton count={2} />}
      {isError && <ErrorState onRetry={refetch} />}

      <div className="flex flex-col gap-3">
        {configs?.map((config) => (
          <ProviderCard key={config.id} config={config} schema={catalog?.find((c) => c.provider === config.provider)?.fields} />
        ))}
      </div>
    </div>
  )
}
