import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { clsx } from 'clsx'
import { useAdvertisements, type AdPlacement } from '../../lib/api/advertisements'

const AUTO_ADVANCE_MS = 5000

/**
 * Renders the active ad(s) targeting one placement (see AdPlacement) — or
 * nothing at all if none are configured/active there, same "no placeholder
 * ad space" principle as the homepage BannerCarousel. Independent of that
 * component on purpose: ads are a separate concept (admin: "Advertising")
 * from the curated homepage banner slider (admin: "Homepage banners").
 */
export function AdSlot({ placement, className, aspectClassName = 'aspect-[16/9]' }: {
  placement: AdPlacement
  className?: string
  aspectClassName?: string
}) {
  const { data: ads } = useAdvertisements(placement)
  const [index, setIndex] = useState(0)

  const slides = ads ?? []

  useEffect(() => {
    if (slides.length <= 1) return
    const timer = setInterval(() => setIndex((i) => (i + 1) % slides.length), AUTO_ADVANCE_MS)
    return () => clearInterval(timer)
  }, [slides.length])

  if (slides.length === 0) return null

  const current = slides[Math.min(index, slides.length - 1)]

  const Slide = (
    <div className={clsx('relative w-full overflow-hidden rounded-card bg-stone-100', aspectClassName)}>
      <img src={current.image_url} alt={current.title ?? ''} className="h-full w-full object-cover" />
      {(current.title || current.subtitle) && (
        <div className="absolute inset-0 flex flex-col justify-end gap-0.5 bg-gradient-to-t from-ink-900/70 via-ink-900/10 to-transparent p-3">
          {current.title && <p className="font-display text-sm font-semibold text-white">{current.title}</p>}
          {current.subtitle && <p className="line-clamp-2 text-xs text-white/90">{current.subtitle}</p>}
          {current.cta_label && (
            <span className="mt-1 inline-flex w-fit items-center rounded-lg bg-white px-2.5 py-1 text-xs font-semibold text-ink-900">
              {current.cta_label}
            </span>
          )}
        </div>
      )}
    </div>
  )

  return (
    <div className={className}>
      <p className="mb-1.5 text-[10px] font-semibold uppercase tracking-wide text-ink-700/40">Advertisement</p>
      {current.link_url ? <Link to={current.link_url}>{Slide}</Link> : Slide}
      {slides.length > 1 && (
        <div className="mt-2 flex justify-center gap-1.5">
          {slides.map((s, i) => (
            <button
              key={s.id}
              type="button"
              aria-label={`Show ad ${i + 1}`}
              onClick={() => setIndex(i)}
              className={clsx('h-1.5 rounded-full transition-all', i === index ? 'w-5 bg-trust-700' : 'w-1.5 bg-stone-300')}
            />
          ))}
        </div>
      )}
    </div>
  )
}
