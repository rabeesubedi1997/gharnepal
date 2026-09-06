import { useState } from 'react'
import { Trash2 } from 'lucide-react'
import {
  useAdminAmenities,
  useCreateAmenity,
  useDeleteAmenity,
  useUpdateAmenity,
  type AdminAmenity,
} from '../../lib/api/admin'
import { getErrorMessage } from '../../lib/api/errors'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { Input } from '../../components/ui/Input'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'

export function Amenities() {
  const { data, isPending, isError, refetch } = useAdminAmenities()
  const create = useCreateAmenity()
  const update = useUpdateAmenity()
  const remove = useDeleteAmenity()

  const [key, setKey] = useState('')
  const [name, setName] = useState('')
  const [category, setCategory] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [editing, setEditing] = useState<AdminAmenity | null>(null)

  const handleCreate = () => {
    setError(null)
    create.mutate(
      { key: key.trim(), name: name.trim(), category: category.trim() || undefined },
      {
        onSuccess: () => {
          setKey('')
          setName('')
          setCategory('')
        },
        onError: (e) => setError(getErrorMessage(e)),
      },
    )
  }

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="font-display text-2xl font-semibold text-ink-900">Amenities</h1>
        <p className="mt-1 text-sm text-ink-700/70">The catalog owners pick from when posting a listing.</p>
      </div>

      <Card className="flex flex-col gap-3 p-4">
        <h2 className="font-display text-base font-semibold text-ink-900">Add an amenity</h2>
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
          <Input label="Key (unique, no spaces)" placeholder="e.g. rooftop_access" value={key} onChange={(e) => setKey(e.target.value)} />
          <Input label="Display name" placeholder="e.g. Rooftop access" value={name} onChange={(e) => setName(e.target.value)} />
          <Input label="Category (optional)" placeholder="e.g. outdoor" value={category} onChange={(e) => setCategory(e.target.value)} />
        </div>
        {error && <p className="text-sm text-danger-600">{error}</p>}
        <Button
          className="self-start"
          isLoading={create.isPending}
          disabled={!key.trim() || !name.trim()}
          onClick={handleCreate}
        >
          Add amenity
        </Button>
      </Card>

      {isPending && <PropertyGridSkeleton count={4} />}
      {isError && <ErrorState onRetry={refetch} />}
      {!isPending && !isError && data?.length === 0 && <EmptyState title="No amenities yet" description="Add one above." />}

      <div className="flex flex-col gap-2">
        {data?.map((amenity) => (
          <Card key={amenity.id} className="flex flex-wrap items-center justify-between gap-3 p-3">
            {editing?.id === amenity.id ? (
              <EditRow
                amenity={editing}
                isSaving={update.isPending}
                onCancel={() => setEditing(null)}
                onSave={(input) =>
                  update.mutate({ id: amenity.id, ...input }, { onSuccess: () => setEditing(null) })
                }
              />
            ) : (
              <>
                <div className="flex items-center gap-2">
                  <span className="font-medium text-ink-900">{amenity.name}</span>
                  <Badge tone="neutral">{amenity.key}</Badge>
                  {amenity.category && <Badge tone="trust">{amenity.category}</Badge>}
                </div>
                <div className="flex gap-2">
                  <Button size="sm" variant="outline" onClick={() => setEditing(amenity)}>
                    Edit
                  </Button>
                  <button
                    type="button"
                    aria-label={`Delete ${amenity.name}`}
                    onClick={() => remove.mutate(amenity.id)}
                    className="rounded-md p-1.5 text-danger-600 hover:bg-danger-100/40"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </>
            )}
          </Card>
        ))}
      </div>
    </div>
  )
}

function EditRow({
  amenity,
  isSaving,
  onSave,
  onCancel,
}: {
  amenity: AdminAmenity
  isSaving: boolean
  onSave: (input: { name: string; category?: string }) => void
  onCancel: () => void
}) {
  const [name, setName] = useState(amenity.name)
  const [category, setCategory] = useState(amenity.category ?? '')

  return (
    <div className="flex w-full flex-wrap items-center gap-2">
      <Input value={name} onChange={(e) => setName(e.target.value)} className="max-w-xs flex-1" />
      <Input value={category} onChange={(e) => setCategory(e.target.value)} placeholder="Category" className="max-w-[10rem]" />
      <Button size="sm" isLoading={isSaving} onClick={() => onSave({ name: name.trim(), category: category.trim() || undefined })}>
        Save
      </Button>
      <Button size="sm" variant="ghost" onClick={onCancel}>
        Cancel
      </Button>
    </div>
  )
}
