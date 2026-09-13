import { useRef } from 'react'
import { ImagePlus, LayoutPanelTop, Trash2 } from 'lucide-react'
import { useDeletePropertyMedia, useUploadPropertyMedia } from '../../lib/api/properties'
import { Button } from '../../components/ui/Button'
import type { MediaItem } from '../../lib/api/listings'

interface Props {
  propertyId: number
  media: MediaItem[]
  onMediaAdded: (item: MediaItem) => void
  onMediaRemoved: (mediaId: number) => void
  onNext: () => void
  onBack: () => void
}

export function MediaStep({ propertyId, media, onMediaAdded, onMediaRemoved, onNext, onBack }: Props) {
  const upload = useUploadPropertyMedia()
  const remove = useDeletePropertyMedia()
  const inputRef = useRef<HTMLInputElement>(null)
  const floorPlanInputRef = useRef<HTMLInputElement>(null)

  const photos = media.filter((item) => item.type === 'image')
  // A floor plan is a single reference image, not part of the photo gallery —
  // Rightmove's own data shows listings with one see meaningfully higher
  // enquiry rates, and it costs nothing new to add (the media pipeline
  // already supports this type; it was just never surfaced in the wizard).
  const floorPlan = media.find((item) => item.type === 'floor_plan')

  const handleFiles = async (files: FileList | null) => {
    if (!files) return
    for (const file of Array.from(files)) {
      try {
        const item = await upload.mutateAsync({ propertyId, type: 'image', file })
        onMediaAdded(item)
      } catch {
        // upload.error surfaces the message below; continue with remaining files
      }
    }
    if (inputRef.current) inputRef.current.value = ''
  }

  const handleFloorPlan = async (files: FileList | null) => {
    const file = files?.[0]
    if (!file) return
    try {
      const item = await upload.mutateAsync({ propertyId, type: 'floor_plan', file })
      onMediaAdded(item)
    } catch {
      // upload.error surfaces the message below
    }
    if (floorPlanInputRef.current) floorPlanInputRef.current.value = ''
  }

  return (
    <div className="flex flex-col gap-4">
      <p className="text-sm text-ink-700/70">
        Add clear photos of the property — exteriors, each room, and the surrounding area help
        buyers trust the listing. You can add more later.
      </p>

      <label className="flex cursor-pointer flex-col items-center gap-2 rounded-card border-2 border-dashed border-stone-200 bg-white px-6 py-10 text-center hover:border-trust-700">
        <ImagePlus className="h-8 w-8 text-ink-700/40" aria-hidden="true" />
        <span className="text-sm font-medium text-ink-900">Click to upload photos</span>
        <span className="text-xs text-ink-700/60">JPG, PNG, or WebP — up to 20MB each</span>
        <input
          ref={inputRef}
          type="file"
          accept="image/jpeg,image/png,image/webp"
          multiple
          className="sr-only"
          onChange={(e) => handleFiles(e.target.files)}
        />
      </label>

      {upload.isPending && <p className="text-sm text-ink-700/70">Uploading…</p>}
      {upload.isError && <p className="text-sm text-danger-600">Couldn't upload that file. Please try again.</p>}

      {photos.length > 0 && (
        <div className="grid grid-cols-3 gap-3 sm:grid-cols-4">
          {photos.map((item) => (
            <div key={item.id} className="group relative aspect-square overflow-hidden rounded-lg border border-stone-200">
              <img src={item.url} alt="" className="h-full w-full object-cover" />
              <button
                type="button"
                aria-label="Remove photo"
                onClick={() => {
                  remove.mutate({ propertyId, mediaId: item.id })
                  onMediaRemoved(item.id)
                }}
                className="absolute right-1 top-1 rounded-full bg-ink-900/70 p-1 text-white opacity-0 transition-opacity group-hover:opacity-100"
              >
                <Trash2 className="h-3.5 w-3.5" />
              </button>
            </div>
          ))}
        </div>
      )}

      <div className="border-t border-stone-200 pt-4">
        <p className="mb-2 text-sm font-medium text-ink-900">Floor plan (optional)</p>
        <p className="mb-3 text-xs text-ink-700/60">
          Listings with a floor plan tend to get noticeably more enquiries — a hand-drawn or
          phone-photographed plan works fine.
        </p>
        {floorPlan ? (
          <div className="group relative w-40 overflow-hidden rounded-lg border border-stone-200">
            <img src={floorPlan.url} alt="Floor plan" className="h-40 w-40 object-cover" />
            <button
              type="button"
              aria-label="Remove floor plan"
              onClick={() => {
                remove.mutate({ propertyId, mediaId: floorPlan.id })
                onMediaRemoved(floorPlan.id)
              }}
              className="absolute right-1 top-1 rounded-full bg-ink-900/70 p-1 text-white opacity-0 transition-opacity group-hover:opacity-100"
            >
              <Trash2 className="h-3.5 w-3.5" />
            </button>
          </div>
        ) : (
          <label className="flex w-fit cursor-pointer items-center gap-2 rounded-lg border-2 border-dashed border-stone-200 bg-white px-4 py-3 text-sm hover:border-trust-700">
            <LayoutPanelTop className="h-5 w-5 text-ink-700/40" aria-hidden="true" />
            <span className="font-medium text-ink-900">Upload a floor plan</span>
            <input
              ref={floorPlanInputRef}
              type="file"
              accept="image/jpeg,image/png,application/pdf"
              className="sr-only"
              onChange={(e) => handleFloorPlan(e.target.files)}
            />
          </label>
        )}
      </div>

      <div className="mt-2 flex justify-between">
        <Button variant="outline" onClick={onBack} type="button">
          Back
        </Button>
        <Button onClick={onNext} disabled={photos.length === 0}>
          Continue to pricing
        </Button>
      </div>
      {photos.length === 0 && (
        <p className="text-right text-xs text-ink-700/60">Add at least one photo to continue.</p>
      )}
    </div>
  )
}
