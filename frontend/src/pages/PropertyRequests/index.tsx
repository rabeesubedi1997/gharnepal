import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { ClipboardList, MapPin, MessageCircle, Plus, X } from 'lucide-react'
import {
  useClosePropertyRequest,
  useCreatePropertyRequest,
  usePropertyRequests,
  type CreatePropertyRequestInput,
  type PropertyRequest,
  type PropertyRequestFilters,
} from '../../lib/api/propertyRequests'
import { useStartConversation } from '../../lib/api/messaging'
import { useMunicipalities } from '../../lib/api/locations'
import { useStaticPageSeo } from '../../lib/api/seo'
import { getErrorMessage } from '../../lib/api/errors'
import { useRequireAuth } from '../../components/auth/AuthGateProvider'
import { useToast } from '../../components/ui/Toast'
import { formatNprCompact } from '../../design-system/tokens'
import { SeoHead } from '../../components/seo/SeoHead'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { Input, Select } from '../../components/ui/Input'
import { Modal } from '../../components/ui/Modal'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'

const PROPERTY_TYPE_LABEL: Record<string, string> = {
  room: 'Room',
  apartment: 'Apartment',
  house: 'House',
  land: 'Land',
  commercial: 'Commercial',
}

function budgetLabel(min: number | null, max: number | null): string | null {
  if (min == null && max == null) return null
  if (min != null && max != null) return `${formatNprCompact(min)} – ${formatNprCompact(max)}`
  if (min != null) return `${formatNprCompact(min)}+`
  return `Up to ${formatNprCompact(max!)}`
}

export function PropertyRequests() {
  const [filters, setFilters] = useState<PropertyRequestFilters>({})
  const { data, isPending, isError, refetch } = usePropertyRequests(filters)
  const { data: municipalities } = useMunicipalities()
  const { data: seo } = useStaticPageSeo('property-requests')
  const requireAuth = useRequireAuth()

  const [postOpen, setPostOpen] = useState(false)
  const [respondingTo, setRespondingTo] = useState<PropertyRequest | null>(null)
  const closeRequest = useClosePropertyRequest()

  return (
    <div className="flex flex-col gap-6">
      <SeoHead seo={seo} />
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="font-display text-2xl font-semibold text-ink-900">Property requests</h1>
          <p className="mt-1 max-w-xl text-sm text-ink-700/70">
            Looking for something specific? Post what you need, and owners or agents with a match can reach out —
            or browse what other buyers and renters are looking for.
          </p>
        </div>
        <Button onClick={() => requireAuth(() => setPostOpen(true))}>
          <Plus className="h-4 w-4" /> Post a request
        </Button>
      </div>

      <div className="flex flex-wrap items-center gap-3">
        <Select
          value={filters.purpose ?? ''}
          onChange={(e) => setFilters((f) => ({ ...f, purpose: (e.target.value || undefined) as 'sale' | 'rent' | undefined }))}
          className="w-40"
          aria-label="Filter by purpose"
        >
          <option value="">Buying or renting</option>
          <option value="sale">Buying</option>
          <option value="rent">Renting</option>
        </Select>
        <Select
          value={filters.property_type ?? ''}
          onChange={(e) => setFilters((f) => ({ ...f, property_type: (e.target.value || undefined) as PropertyRequestFilters['property_type'] }))}
          className="w-44"
          aria-label="Filter by property type"
        >
          <option value="">Any property type</option>
          {Object.entries(PROPERTY_TYPE_LABEL).map(([value, label]) => (
            <option key={value} value={value}>{label}</option>
          ))}
        </Select>
        <Select
          value={filters.municipality_id ?? ''}
          onChange={(e) => setFilters((f) => ({ ...f, municipality_id: e.target.value ? Number(e.target.value) : undefined }))}
          className="w-48"
          aria-label="Filter by city"
        >
          <option value="">Any city</option>
          {municipalities?.map((m) => (
            <option key={m.id} value={m.id}>{m.name}</option>
          ))}
        </Select>
      </div>

      {isPending && <PropertyGridSkeleton count={4} />}
      {isError && <ErrorState onRetry={refetch} description="Couldn't load requests right now." />}

      {!isPending && !isError && data?.data.length === 0 && (
        <EmptyState
          icon={<ClipboardList className="h-8 w-8" aria-hidden="true" />}
          title="No open requests match"
          description="Try a different filter, or be the first to post one."
        />
      )}

      <div className="flex flex-col gap-3">
        {data?.data.map((r) => (
          <Card key={r.id} className="flex flex-col gap-2 p-4">
            <div className="flex flex-wrap items-start justify-between gap-2">
              <div>
                <div className="flex flex-wrap items-center gap-2">
                  <Badge tone={r.purpose === 'rent' ? 'trust' : 'accent'}>{r.purpose === 'rent' ? 'Renting' : 'Buying'}</Badge>
                  {r.property_type && <Badge tone="neutral">{PROPERTY_TYPE_LABEL[r.property_type]}</Badge>}
                  {r.is_mine && <Badge tone="warning">Your request</Badge>}
                </div>
                <p className="mt-2 flex flex-wrap items-center gap-x-3 gap-y-1 text-sm text-ink-900">
                  {budgetLabel(r.budget_min, r.budget_max) && <span className="font-semibold text-trust-700">{budgetLabel(r.budget_min, r.budget_max)}</span>}
                  {r.bedrooms_min != null && <span>{r.bedrooms_min}+ bedrooms</span>}
                  {r.municipality && (
                    <span className="flex items-center gap-1 text-ink-700/70">
                      <MapPin className="h-3.5 w-3.5" aria-hidden="true" /> {r.municipality}
                    </span>
                  )}
                </p>
                {r.notes && <p className="mt-1 text-sm text-ink-700/70">{r.notes}</p>}
                <p className="mt-1 text-xs text-ink-700/50">
                  Posted by {r.posted_by ?? 'a Ghar Nepal user'} · {new Date(r.created_at).toLocaleDateString()}
                </p>
              </div>
              {r.is_mine ? (
                <Button
                  variant="outline"
                  size="sm"
                  isLoading={closeRequest.isPending}
                  onClick={() => closeRequest.mutate(r.id)}
                >
                  <X className="h-4 w-4" /> Close request
                </Button>
              ) : (
                <Button size="sm" onClick={() => requireAuth(() => setRespondingTo(r))}>
                  <MessageCircle className="h-4 w-4" /> Respond
                </Button>
              )}
            </div>
          </Card>
        ))}
      </div>

      <PostRequestModal open={postOpen} onClose={() => setPostOpen(false)} />
      <RespondModal request={respondingTo} onClose={() => setRespondingTo(null)} />
    </div>
  )
}

function PostRequestModal({ open, onClose }: { open: boolean; onClose: () => void }) {
  const { data: municipalities } = useMunicipalities()
  const create = useCreatePropertyRequest()
  const toast = useToast()
  const [error, setError] = useState<string | null>(null)

  const [form, setForm] = useState({
    purpose: 'rent' as 'sale' | 'rent',
    property_type: '',
    budget_min: '',
    budget_max: '',
    bedrooms_min: '',
    municipality_id: '',
    notes: '',
  })

  const handleClose = () => {
    setError(null)
    onClose()
  }

  const handleSubmit = () => {
    setError(null)
    const input: CreatePropertyRequestInput = {
      purpose: form.purpose,
      property_type: (form.property_type || undefined) as CreatePropertyRequestInput['property_type'],
      budget_min: form.budget_min ? Number(form.budget_min) : undefined,
      budget_max: form.budget_max ? Number(form.budget_max) : undefined,
      bedrooms_min: form.bedrooms_min ? Number(form.bedrooms_min) : undefined,
      municipality_id: form.municipality_id ? Number(form.municipality_id) : undefined,
      notes: form.notes.trim() || undefined,
    }
    create.mutate(input, {
      onSuccess: () => {
        toast.success('Posted! Owners and agents with a match can now reach out to you.')
        handleClose()
      },
      onError: (e) => setError(getErrorMessage(e)),
    })
  }

  return (
    <Modal open={open} onClose={handleClose} title="Post a property request">
      <div className="flex flex-col gap-3">
        <Select label="I'm" value={form.purpose} onChange={(e) => setForm((f) => ({ ...f, purpose: e.target.value as 'sale' | 'rent' }))}>
          <option value="rent">Renting</option>
          <option value="sale">Buying</option>
        </Select>
        <Select label="Property type (optional)" value={form.property_type} onChange={(e) => setForm((f) => ({ ...f, property_type: e.target.value }))}>
          <option value="">Any type</option>
          {Object.entries(PROPERTY_TYPE_LABEL).map(([value, label]) => (
            <option key={value} value={value}>{label}</option>
          ))}
        </Select>
        <div className="grid grid-cols-2 gap-3">
          <Input label="Budget min (Rs, optional)" type="number" min={0} placeholder="No minimum" value={form.budget_min} onChange={(e) => setForm((f) => ({ ...f, budget_min: e.target.value }))} />
          <Input label="Budget max (Rs, optional)" type="number" min={0} placeholder="No maximum" value={form.budget_max} onChange={(e) => setForm((f) => ({ ...f, budget_max: e.target.value }))} />
        </div>
        <Input label="Minimum bedrooms (optional)" type="number" min={0} max={20} placeholder="e.g. 2" value={form.bedrooms_min} onChange={(e) => setForm((f) => ({ ...f, bedrooms_min: e.target.value }))} />
        <Select label="Preferred city (optional)" value={form.municipality_id} onChange={(e) => setForm((f) => ({ ...f, municipality_id: e.target.value }))}>
          <option value="">Any city</option>
          {municipalities?.map((m) => (
            <option key={m.id} value={m.id}>{m.name}</option>
          ))}
        </Select>
        <label className="flex flex-col gap-1.5">
          <span className="text-sm font-medium text-ink-900">Additional details (optional)</span>
          <textarea
            rows={3}
            maxLength={1000}
            value={form.notes}
            onChange={(e) => setForm((f) => ({ ...f, notes: e.target.value }))}
            placeholder="e.g. near a school, ground floor preferred, 2 parking spaces"
            className="rounded-lg border border-stone-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-trust-700"
          />
        </label>
        {error && <p className="text-sm text-danger-600">{error}</p>}
        <Button isLoading={create.isPending} onClick={handleSubmit}>
          Post request
        </Button>
      </div>
    </Modal>
  )
}

function RespondModal({ request, onClose }: { request: PropertyRequest | null; onClose: () => void }) {
  const [message, setMessage] = useState('')
  const [error, setError] = useState<string | null>(null)
  const start = useStartConversation()
  const navigate = useNavigate()
  const toast = useToast()

  const handleClose = () => {
    setMessage('')
    setError(null)
    onClose()
  }

  return (
    <Modal open={!!request} onClose={handleClose} title="Respond to this request">
      <div className="flex flex-col gap-3">
        <textarea
          rows={4}
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          placeholder="Hi, I have a property that might match what you're looking for."
          className="rounded-lg border border-stone-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-trust-700"
        />
        {error && <p className="text-sm text-danger-600">{error}</p>}
        <Button
          isLoading={start.isPending}
          disabled={!message.trim()}
          onClick={() =>
            request &&
            start.mutate(
              { propertyRequestId: request.id, message: message.trim() },
              {
                onSuccess: (conversation) => {
                  toast.success('Message sent.')
                  handleClose()
                  navigate(`/messages/${conversation.id}`)
                },
                onError: (e) => setError(getErrorMessage(e)),
              },
            )
          }
        >
          Send message
        </Button>
      </div>
    </Modal>
  )
}
