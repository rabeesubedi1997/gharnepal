/**
 * Full-bleed hero backdrop — layered Himalayan-ridge silhouettes over a
 * dusk-to-night gradient, deliberately illustrated (SVG/CSS) rather than a
 * stock photo: no licensing question, no risk of it looking like a generic
 * stock-photo hero, and it costs nothing to load. The motif (hills, snow
 * caps, a rising moon) is honest to the product (Nepal) rather than a
 * borrowed gradient template.
 */
export function HeroBackdrop() {
  return (
    <div className="pointer-events-none absolute inset-0 overflow-hidden" aria-hidden="true">
      {/* Dusk sky gradient */}
      <div
        className="absolute inset-0"
        style={{
          background:
            'linear-gradient(180deg, #0d2b22 0%, #123f31 35%, #1a5643 60%, #123f31 100%)',
        }}
      />
      {/* Moon glow */}
      <div
        className="absolute right-[12%] top-[14%] h-24 w-24 rounded-full opacity-90 blur-[2px] sm:h-32 sm:w-32"
        style={{ background: 'radial-gradient(circle, #fdf6e3 0%, #f3e8c8 55%, transparent 75%)' }}
      />
      <div
        className="absolute right-[10%] top-[10%] h-48 w-48 rounded-full opacity-30 blur-3xl sm:h-64 sm:w-64"
        style={{ background: 'radial-gradient(circle, #f3e8c8, transparent 70%)' }}
      />

      {/* Far ridge — kept low and low-contrast so it reads as atmospheric
          haze behind the mid/near ridges, never as its own isolated peak */}
      <svg className="absolute bottom-0 left-0 h-2/3 w-full" viewBox="0 0 1440 400" preserveAspectRatio="none" fill="none">
        <path
          d="M0 340 L200 300 L380 320 L560 270 L760 310 L960 260 L1160 305 L1440 275 L1440 400 L0 400 Z"
          fill="#0a2019"
          opacity="0.5"
        />
      </svg>
      {/* Mid ridge with snow caps */}
      <svg className="absolute bottom-0 left-0 h-1/2 w-full" viewBox="0 0 1440 300" preserveAspectRatio="none" fill="none">
        <path
          d="M0 260 L200 140 L340 200 L520 80 L680 190 L860 60 L1040 180 L1220 100 L1440 210 L1440 300 L0 300 Z"
          fill="#0d2b22"
        />
        <path d="M520 80 L560 110 L500 118 Z" fill="#e7ede8" opacity="0.9" />
        <path d="M860 60 L905 95 L838 104 Z" fill="#e7ede8" opacity="0.9" />
        <path d="M1220 100 L1258 128 L1200 136 Z" fill="#e7ede8" opacity="0.85" />
      </svg>
      {/* Near ridge, darkest */}
      <svg className="absolute bottom-0 left-0 h-1/3 w-full" viewBox="0 0 1440 180" preserveAspectRatio="none" fill="none">
        <path
          d="M0 160 L240 60 L440 130 L680 30 L900 120 L1140 50 L1440 140 L1440 180 L0 180 Z"
          fill="#061712"
        />
      </svg>

      {/* Bottom fade so foreground content stays legible over any ridge */}
      <div className="absolute inset-x-0 bottom-0 h-40 bg-gradient-to-t from-[#061712] to-transparent" />
    </div>
  )
}
