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
import { useToast } from '../../components/ui/Toast'

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

function AddProviderForm() {
  const { data: catalog } = useAiProviderCatalog()
  const create = useCreateAiProvider()

  const [provider, setProvider] = useState('')
  const [label, setLabel] = useState('')
  const [credentials, setCredentials] = useState<Record<string, string>>({})
  const [error, setError] = useState<string | null>(null)

  const schema = catalog?.find((c) => c.provider === provider)

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

  return (
    <Card className="flex flex-col gap-3 p-4">
      <h2 className="font-display text-base font-semibold text-ink-900">Add an AI agent</h2>
      <p className="text-xs text-ink-700/60">
        Add as many as you like — including more than one of the same kind (e.g. two different Claude keys, or several "Custom" agents each
        pointing at a different OpenAI-compatible vendor). Only one can be Active at a time.
      </p>
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
        <Input label="Name" placeholder="e.g. Claude — production key" value={label} onChange={(e) => setLabel(e.target.value)} />
      </div>

      {provider === 'custom' && (
        <p className="text-xs text-ink-700/60">
          Any AI agent whose API speaks the OpenAI Chat Completions format works here — Groq, Together, DeepSeek, OpenRouter, a local Ollama
          instance, etc. Point it at that vendor's base URL, drop in the API key and model name, and it works immediately once saved and
          switched Active — no code changes needed.
        </p>
      )}

      {schema && <CredentialFields fields={schema.fields} values={credentials} onChange={(k, v) => setCredentials((c) => ({ ...c, [k]: v }))} />}

      {error && <p className="text-sm text-danger-600">{error}</p>}
      <Button className="self-start" size="sm" isLoading={create.isPending} disabled={!provider || !label.trim()} onClick={handleCreate}>
        Add
      </Button>
    </Card>
  )
}

function ProviderCard({
  config,
  schema,
  otherEnabled,
}: {
  config: AdminAiProviderConfig
  schema?: AiProviderCredentialField[]
  /** The one other config currently Active, if any — enabling this one will switch it off. */
  otherEnabled?: AdminAiProviderConfig
}) {
  const update = useUpdateAiProvider()
  const remove = useDeleteAiProvider()
  const toast = useToast()
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

  const handleToggleActive = (checked: boolean) => {
    if (checked && otherEnabled) {
      const proceed = window.confirm(
        `Only one AI agent can be active at a time. Enabling "${config.label}" will automatically switch off "${otherEnabled.label}" — its own credentials stay saved, just inactive. Continue?`,
      )
      if (!proceed) return
    }

    update.mutate(
      { id: config.id, is_enabled: checked },
      {
        onSuccess: ({ disabledOthers }) => {
          if (disabledOthers.length > 0) {
            toast.success(
              `"${config.label}" is now active. "${disabledOthers.map((d) => d.label).join('", "')}" ${disabledOthers.length > 1 ? 'were' : 'was'} switched off automatically — only one AI agent can be active at a time.`,
            )
          } else if (checked) {
            toast.success(`"${config.label}" is now active.`)
          }
        },
        onError: (e) => toast.error(getErrorMessage(e)),
      },
    )
  }

  const handleDelete = () => {
    if (!window.confirm(`Remove "${config.label}"? This deletes its saved credentials — it can't be undone.`)) return
    remove.mutate(config.id, { onError: (e) => toast.error(getErrorMessage(e)) })
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
              onChange={(e) => handleToggleActive(e.target.checked)}
              className="h-4 w-4 rounded border-stone-300 text-trust-700"
            />
            Active
          </label>
          <button type="button" onClick={() => setEditing((v) => !v)} className="text-xs font-medium text-link-600 hover:text-link-700">
            {editing ? 'Cancel' : 'Edit'}
          </button>
          <button type="button" aria-label="Delete" onClick={handleDelete} className="rounded-md p-1 text-danger-600 hover:bg-danger-100/40">
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
  const currentlyActive = configs?.find((c) => c.is_enabled)

  return (
    <div className="flex flex-col gap-6">
      <AdminPageHeader
        icon={Sparkles}
        title="AI assistant"
        description="The property-search assistant runs on a free, built-in search engine by default — no API key needed, no cost. Add any number of AI agents below — Claude, OpenAI, Gemini, or a Custom OpenAI-compatible agent for anything else — and mark one Active to upgrade to a genuinely open-ended conversation instead. Only one agent can be active at a time; enabling one switches any other off (you'll be asked to confirm first). Leave everything below empty to keep the free default."
      />

      <AddProviderForm />

      {isPending && <PropertyGridSkeleton count={2} />}
      {isError && <ErrorState onRetry={refetch} />}

      <div className="flex flex-col gap-3">
        {configs?.map((config) => (
          <ProviderCard
            key={config.id}
            config={config}
            schema={catalog?.find((c) => c.provider === config.provider)?.fields}
            otherEnabled={!config.is_enabled && currentlyActive && currentlyActive.id !== config.id ? currentlyActive : undefined}
          />
        ))}
      </div>
    </div>
  )
}
