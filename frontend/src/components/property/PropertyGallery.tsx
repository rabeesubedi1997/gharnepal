import { useEffect, useRef, useState } from 'react'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { clsx } from 'clsx'
import type { MediaItem } from '../../lib/api/listings'

/** Sliding photo gallery for a listing's detail page — arrow nav, swipe on
 * touch devices, keyboard arrows, and a smooth slide transition instead of
 * an instant image swap. Falls back to a single static image when there's
 * only one photo, and an empty state when there are none. */
export function PropertyGallery({ images, title }: { images: MediaItem[]; title: string }) {
  const [index, setIndex] = useState(0)
  const touchStartX = useRef<number | null>(null)

  const go = (next: number) => setIndex(((next % images.length) + images.length) % images.length)

  useEffect(() => {
    if (images.length <= 1) return
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'ArrowLeft') go(index - 1)
      if (e.key === 'ArrowRight') go(index + 1)
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [index, images.length])

  if (images.length === 0) {
    return (
      <div className="flex aspect-video w-full items-center justify-center rounded-card bg-stone-100 text-ink-700/40">
        No photos yet
      </div>
    )
  }

  return (
    <div className="flex flex-col gap-2">
      <div
        className="relative aspect-video w-full overflow-hidden rounded-card bg-stone-100"
        onTouchStart={(e) => {
          touchStartX.current = e.touches[0].clientX
        }}
        onTouchEnd={(e) => {
          if (touchStartX.current == null) return
          const delta = e.changedTouches[0].clientX - touchStartX.current
          if (Math.abs(delta) > 40) go(index + (delta < 0 ? 1 : -1))
          touchStartX.current = null
        }}
      >
        <div
          className="flex h-full transition-transform duration-300 ease-out"
          // The track is `images.length * 100%` wide, so a CSS percentage
          // translate — relative to the track's OWN width, not the visible
          // container — must be scaled down by the same factor to move by
          // exactly one slide (one container-width) per step.
          style={{ transform: `translateX(-${(index * 100) / images.length}%)`, width: `${images.length * 100}%` }}
        >
          {images.map((img) => (
            <div key={img.id} className="h-full shrink-0" style={{ width: `${100 / images.length}%` }}>
              <img src={img.url} alt={title} className="h-full w-full object-cover" />
            </div>
          ))}
        </div>

        {images.length > 1 && (
          <>
            <button
              type="button"
              aria-label="Previous photo"
              onClick={() => go(index - 1)}
              className="absolute left-2 top-1/2 -translate-y-1/2 rounded-full bg-white/80 p-1.5 text-ink-900 shadow transition-colors hover:bg-white"
            >
              <ChevronLeft className="h-5 w-5" />
            </button>
            <button
              type="button"
              aria-label="Next photo"
              onClick={() => go(index + 1)}
              className="absolute right-2 top-1/2 -translate-y-1/2 rounded-full bg-white/80 p-1.5 text-ink-900 shadow transition-colors hover:bg-white"
            >
              <ChevronRight className="h-5 w-5" />
            </button>
            <span className="absolute bottom-3 right-3 rounded-full bg-ink-900/70 px-2.5 py-1 text-xs font-medium text-white">
              {index + 1} / {images.length}
            </span>
          </>
        )}
      </div>

      {images.length > 1 && (
        <div className="flex gap-2 overflow-x-auto">
          {images.map((img, i) => (
            <button
              key={img.id}
              onClick={() => setIndex(i)}
              aria-label={`Show photo ${i + 1}`}
              className={clsx(
                'h-16 w-24 shrink-0 overflow-hidden rounded-lg border-2 transition-colors',
                i === index ? 'border-trust-700' : 'border-transparent hover:border-stone-200',
              )}
            >
              <img src={img.url} alt="" className="h-full w-full object-cover" />
            </button>
          ))}
        </div>
      )}
    </div>
  )
}
