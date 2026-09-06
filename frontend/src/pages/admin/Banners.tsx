import { useRef, useState } from 'react'
import { ArrowDown, ArrowUp, GalleryHorizontal, Trash2 } from 'lucide-react'
import {
  useAdminBanners,
  useCreateBanner,
  useDeleteBanner,
  useUpdateBanner,
} from '../../lib/api/admin'
import type { Banner } from '../../lib/api/banners'
import { getErrorMessage } from '../../lib/api/errors'
import { AdminPageHeader } from '../../components/admin/AdminPageHeader'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { Input } from '../../components/ui/Input'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'

export function Banners() {
  const { data, isPending, isError, refetch } = useAdminBanners()
  const create = useCreateBanner()
  const update = useUpdateBanner()
  const remove = useDeleteBanner()

  const [title, setTitle] = useState('')
  const [subtitle, setSubtitle] = useState('')
  const [linkUrl, setLinkUrl] = useState('')
  const [ctaLabel, setCtaLabel] = useState('')
  const [image, setImage] = useState<File | null>(null)
  const [error, setError] = useState<string | null>(null)
  const fileRef = useRef<HTMLInputElement>(null)

  const banners = data ?? []

  const handleCreate = () => {
    if (!image) return
    setError(null)
    create.mutate(
      {
        title: title.trim() || undefined,
        subtitle: subtitle.trim() || undefined,
        link_url: linkUrl.trim() || undefined,
        cta_label: ctaLabel.trim() || undefined,
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

  const move = (banner: Banner, direction: -1 | 1) => {
    const sorted = [...banners].sort((a, b) => a.sort_order - b.sort_order)
    const i = sorted.findIndex((b) => b.id === banner.id)
    const swapWith = sorted[i + direction]
    if (!swapWith) return
    update.mutate({ id: banner.id, sort_order: swapWith.sort_order })
    update.mutate({ id: swapWith.id, sort_order: banner.sort_order })
  }

  return (
    <div className="flex flex-col gap-6">
      <AdminPageHeader
        icon={GalleryHorizontal}
        title="Homepage banners"
        description="Shown as a slider on the homepage, in the order below. Inactive banners are hidden from visitors."
      />

      <Card className="flex flex-col gap-3 p-4">
        <h2 className="font-display text-base font-semibold text-ink-900">Add a banner</h2>
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <Input label="Title (optional)" value={title} onChange={(e) => setTitle(e.target.value)} />
          <Input label="CTA label (optional)" placeholder="e.g. Browse now" value={ctaLabel} onChange={(e) => setCtaLabel(e.target.value)} />
          <Input label="Subtitle (optional)" className="sm:col-span-2" value={subtitle} onChange={(e) => setSubtitle(e.target.value)} />
          <Input
            label="Link URL (optional)"
            placeholder="/search?property_type=land"
            className="sm:col-span-2"
            value={linkUrl}
            onChange={(e) => setLinkUrl(e.target.value)}
          />
        </div>
        <label className="flex flex-col gap-1.5 text-sm font-medium text-ink-900">
          Banner image (recommended ~1600×600)
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
          Add banner
        </Button>
      </Card>

      {isPending && <PropertyGridSkeleton count={3} />}
      {isError && <ErrorState onRetry={refetch} />}
      {!isPending && !isError && banners.length === 0 && (
        <EmptyState title="No banners yet" description="Add one above to start the homepage slider." />
      )}

      <div className="flex flex-col gap-2">
        {[...banners]
          .sort((a, b) => a.sort_order - b.sort_order)
          .map((banner, i) => (
            <Card key={banner.id} className="flex flex-wrap items-center gap-3 p-3">
              <img src={banner.image_url} alt="" className="h-16 w-28 shrink-0 rounded-lg object-cover" />
              <div className="min-w-0 flex-1">
                <p className="truncate font-medium text-ink-900">{banner.title || '(no title)'}</p>
                {banner.subtitle && <p className="truncate text-xs text-ink-700/60">{banner.subtitle}</p>}
              </div>
              <Badge tone={banner.is_active ? 'success' : 'neutral'}>{banner.is_active ? 'active' : 'inactive'}</Badge>
              <div className="flex items-center gap-1">
                <button
                  type="button"
                  aria-label="Move up"
                  disabled={i === 0}
                  onClick={() => move(banner, -1)}
                  className="rounded-md p-1.5 text-ink-700/60 hover:bg-stone-100 disabled:opacity-30"
                >
                  <ArrowUp className="h-4 w-4" />
                </button>
                <button
                  type="button"
                  aria-label="Move down"
                  disabled={i === banners.length - 1}
                  onClick={() => move(banner, 1)}
                  className="rounded-md p-1.5 text-ink-700/60 hover:bg-stone-100 disabled:opacity-30"
                >
                  <ArrowDown className="h-4 w-4" />
                </button>
              </div>
              <Button size="sm" variant="outline" onClick={() => update.mutate({ id: banner.id, is_active: !banner.is_active })}>
                {banner.is_active ? 'Deactivate' : 'Activate'}
              </Button>
              <button
                type="button"
                aria-label="Delete banner"
                onClick={() => remove.mutate(banner.id)}
                className="rounded-md p-1.5 text-danger-600 hover:bg-danger-100/40"
              >
                <Trash2 className="h-4 w-4" />
              </button>
            </Card>
          ))}
      </div>
    </div>
  )
}
