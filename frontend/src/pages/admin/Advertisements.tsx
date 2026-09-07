import { useRef, useState } from 'react'
import { ArrowDown, ArrowUp, Megaphone, Trash2 } from 'lucide-react'
import {
  useAdminAdvertisements,
  useCreateAdvertisement,
  useDeleteAdvertisement,
  useUpdateAdvertisement,
} from '../../lib/api/admin'
import { PLACEMENTS, type Advertisement, type AdPlacement } from '../../lib/api/advertisements'
import { getErrorMessage } from '../../lib/api/errors'
import { AdminPageHeader } from '../../components/admin/AdminPageHeader'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { Input, Select } from '../../components/ui/Input'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'

export function Advertisements() {
  const { data, isPending, isError, refetch } = useAdminAdvertisements()
  const create = useCreateAdvertisement()
  const update = useUpdateAdvertisement()
  const remove = useDeleteAdvertisement()

  const [title, setTitle] = useState('')
  const [subtitle, setSubtitle] = useState('')
  const [linkUrl, setLinkUrl] = useState('')
  const [ctaLabel, setCtaLabel] = useState('')
  const [placement, setPlacement] = useState<AdPlacement>(PLACEMENTS[0].value)
  const [image, setImage] = useState<File | null>(null)
  const [error, setError] = useState<string | null>(null)
  const fileRef = useRef<HTMLInputElement>(null)

  const ads = data ?? []

  const handleCreate = () => {
    if (!image) return
    setError(null)
    create.mutate(
      {
        title: title.trim() || undefined,
        subtitle: subtitle.trim() || undefined,
        link_url: linkUrl.trim() || undefined,
        cta_label: ctaLabel.trim() || undefined,
        placement,
        image,
      },
      {
        onSuccess: () => {
          setTitle('')
          setSubtitle('')
          setLinkUrl('')
          setCtaLabel('')
          setImage(null)
          if (fileRef.current) fileRef.current.value = ''
        },
        onError: (e) => setError(getErrorMessage(e)),
      },
    )
  }

  const move = (ad: Advertisement, siblings: Advertisement[], direction: -1 | 1) => {
    const i = siblings.findIndex((a) => a.id === ad.id)
    const swapWith = siblings[i + direction]
    if (!swapWith) return
    update.mutate({ id: ad.id, sort_order: swapWith.sort_order })
    update.mutate({ id: swapWith.id, sort_order: ad.sort_order })
  }

  return (
    <div className="flex flex-col gap-6">
      <AdminPageHeader
        icon={Megaphone}
        tone="trust"
        title="Advertising"
        description="Targeted ad slots across the site — separate from the homepage banner slider. A slot only shows something while an active ad targets it."
      />

      <Card className="flex flex-col gap-3 p-4">
        <h2 className="font-display text-base font-semibold text-ink-900">Add an advertisement</h2>
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <Select label="Placement" value={placement} onChange={(e) => setPlacement(e.target.value as AdPlacement)}>
            {PLACEMENTS.map((p) => (
              <option key={p.value} value={p.value}>{p.label}</option>
            ))}
          </Select>
          <Input label="CTA label (optional)" placeholder="e.g. Get started" value={ctaLabel} onChange={(e) => setCtaLabel(e.target.value)} />
          <Input label="Title (optional)" value={title} onChange={(e) => setTitle(e.target.value)} />
          <Input
            label="Link URL (optional)"
            placeholder="/search?property_type=land"
            value={linkUrl}
            onChange={(e) => setLinkUrl(e.target.value)}
          />
          <Input label="Subtitle (optional)" className="sm:col-span-2" value={subtitle} onChange={(e) => setSubtitle(e.target.value)} />
        </div>
        <label className="flex flex-col gap-1.5 text-sm font-medium text-ink-900">
          Ad image
          <input
            ref={fileRef}
            type="file"
            accept="image/jpeg,image/png,image/webp"
            onChange={(e) => setImage(e.target.files?.[0] ?? null)}
            className="rounded-lg border border-stone-200 px-3 py-2 text-sm"
          />
        </label>
        {error && <p className="text-sm text-danger-600">{error}</p>}
        <Button className="self-start" isLoading={create.isPending} disabled={!image} onClick={handleCreate}>
          Add advertisement
        </Button>
      </Card>

      {isPending && <PropertyGridSkeleton count={3} />}
      {isError && <ErrorState onRetry={refetch} />}
      {!isPending && !isError && ads.length === 0 && (
        <EmptyState title="No advertisements yet" description="Add one above to fill an ad slot." />
      )}

      {!isPending && !isError && PLACEMENTS.map(({ value, label }) => {
        const group = ads.filter((a) => a.placement === value).sort((a, b) => a.sort_order - b.sort_order)
        if (group.length === 0) return null

        return (
          <div key={value} className="flex flex-col gap-2">
            <h3 className="text-xs font-semibold uppercase tracking-wide text-ink-700/50">{label}</h3>
            {group.map((ad, i) => (
              <Card key={ad.id} className="flex flex-wrap items-center gap-3 p-3">
                <img src={ad.image_url} alt="" className="h-16 w-16 shrink-0 rounded-lg object-cover" />
                <div className="min-w-0 flex-1">
                  <p className="truncate font-medium text-ink-900">{ad.title || '(no title)'}</p>
                  {ad.subtitle && <p className="truncate text-xs text-ink-700/60">{ad.subtitle}</p>}
                </div>
                <Badge tone={ad.is_active ? 'success' : 'neutral'}>{ad.is_active ? 'active' : 'inactive'}</Badge>
                <div className="flex items-center gap-1">
                  <button
                    type="button"
                    aria-label="Move up"
                    disabled={i === 0}
                    onClick={() => move(ad, group, -1)}
                    className="rounded-md p-1.5 text-ink-700/60 hover:bg-stone-100 disabled:opacity-30"
                  >
                    <ArrowUp className="h-4 w-4" />
                  </button>
                  <button
                    type="button"
                    aria-label="Move down"
                    disabled={i === group.length - 1}
                    onClick={() => move(ad, group, 1)}
                    className="rounded-md p-1.5 text-ink-700/60 hover:bg-stone-100 disabled:opacity-30"
                  >
                    <ArrowDown className="h-4 w-4" />
                  </button>
                </div>
                <Button size="sm" variant="outline" onClick={() => update.mutate({ id: ad.id, is_active: !ad.is_active })}>
                  {ad.is_active ? 'Deactivate' : 'Activate'}
                </Button>
                <button
                  type="button"
                  aria-label="Delete advertisement"
                  onClick={() => remove.mutate(ad.id)}
                  className="rounded-md p-1.5 text-danger-600 hover:bg-danger-100/40"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </Card>
            ))}
          </div>
        )
      })}
    </div>
  )
}
