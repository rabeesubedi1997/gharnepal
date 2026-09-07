/**
 * Purely decorative backdrop for the homepage hero — layered mountain-ridge
 * silhouettes plus a soft warm glow. Gives the hero real depth/personality
 * instead of a flat solid-color rectangle, and the motif (hills) is honest
 * to the product (Nepal) rather than a generic stock gradient. Rendered as
 * inline SVG/CSS so it costs nothing to load and never looks like a stock photo.
 */
export function HeroBackdrop() {
  return (
    <div className="pointer-events-none absolute inset-0 overflow-hidden rounded-card" aria-hidden="true">
      <div
        className="absolute -top-24 -left-24 h-72 w-72 rounded-full opacity-40 blur-3xl"
        style={{ background: 'radial-gradient(circle, var(--color-accent-100), transparent 70%)' }}
      />
      <div
        className="absolute -top-16 right-0 h-80 w-80 rounded-full opacity-60 blur-3xl"
        style={{ background: 'radial-gradient(circle, var(--color-trust-100), transparent 70%)' }}
      />
      <svg
        className="absolute bottom-0 left-0 h-32 w-full sm:h-44"
        viewBox="0 0 1440 220"
        preserveAspectRatio="none"
        fill="none"
      >
        <path
          d="M0 180 L180 90 L340 150 L520 40 L700 130 L880 60 L1080 140 L1260 80 L1440 150 L1440 220 L0 220 Z"
          fill="var(--color-trust-100)"
          opacity="0.7"
        />
        <path
          d="M0 220 L220 130 L400 190 L600 100 L780 180 L980 120 L1180 200 L1440 140 L1440 220 Z"
          fill="var(--color-trust-700)"
          opacity="0.08"
        />
      </svg>
    </div>
  )
}
