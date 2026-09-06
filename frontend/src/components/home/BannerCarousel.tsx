import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { clsx } from 'clsx'
import { useBanners } from '../../lib/api/banners'

const AUTO_ADVANCE_MS = 6000

export function BannerCarousel() {
  const { data: banners } = useBanners()
  const [index, setIndex] = useState(0)

  const slides = banners ?? []

  useEffect(() => {
    if (slides.length <= 1) return
    const timer = setInterval(() => setIndex((i) => (i + 1) % slides.length), AUTO_ADVANCE_MS)
    return () => clearInterval(timer)
  }, [slides.length])

  // Nothing configured yet — the homepage's own hero already carries the
  // core value proposition, so this section simply doesn't render rather
  // than showing an empty placeholder.
  if (slides.length === 0) return null

  const current = slides[Math.min(index, slides.length - 1)]

  const Slide = (
    <div className="relative aspect-[21/9] w-full overflow-hidden rounded-card bg-stone-200 sm:aspect-[3/1]">
      <img src={current.image_url} alt={current.title ?? ''} className="h-full w-full object-cover" />
      {(current.title || current.subtitle) && (
        <div className="absolute inset-0 flex flex-col justify-end gap-1 bg-gradient-to-t from-ink-900/70 via-ink-900/10 to-transparent p-4 sm:p-6">
          {current.title && <h3 className="font-display text-lg font-semibold text-white sm:text-2xl">{current.title}</h3>}
          {current.subtitle && <p className="max-w-xl text-sm text-white/90 sm:text-base">{current.subtitle}</p>}
          {current.cta_label && (
            <span className="mt-1 inline-flex w-fit items-center rounded-lg bg-white px-3 py-1.5 text-xs font-semibold text-ink-900 sm:text-sm">
              {current.cta_label}
            </span>
          )}
        </div>
      )}
    </div>
  )

  return (
    <section className="relative">
      {current.link_url ? <Link to={current.link_url}>{Slide}</Link> : Slide}

      {slides.length > 1 && (
        <>
          <button
            type="button"
            aria-label="Previous banner"
            onClick={() => setIndex((i) => (i - 1 + slides.length) % slides.length)}
            className="absolute left-2 top-1/2 -translate-y-1/2 rounded-full bg-white/80 p-1.5 text-ink-900 hover:bg-white"
          >
            <ChevronLeft className="h-5 w-5" />
          </button>
          <button
            type="button"
            aria-label="Next banner"
            onClick={() => setIndex((i) => (i + 1) % slides.length)}
            className="absolute right-2 top-1/2 -translate-y-1/2 rounded-full bg-white/80 p-1.5 text-ink-900 hover:bg-white"
          >
            <ChevronRight className="h-5 w-5" />
          </button>
          <div className="mt-2 flex justify-center gap-1.5">
            {slides.map((s, i) => (
              <button
                key={s.id}
                type="button"
                aria-label={`Go to slide ${i + 1}`}
                onClick={() => setIndex(i)}
                className={clsx('h-1.5 rounded-full transition-all', i === index ? 'w-6 bg-trust-700' : 'w-1.5 bg-stone-300')}
              />
            ))}
          </div>
        </>
      )}
    </section>
  )
}
