/**
 * A fixed, whole-page backdrop — faint mountain-ridge silhouettes anchored
 * to the left and right edges of the viewport, fading to nothing toward the
 * center. On a wide monitor the boxed page content (max-w-[1440px]) leaves
 * plain margins on either side; this gives those margins something quietly
 * designed instead of empty flat color, without stretching any section's
 * own background edge-to-edge (the earlier full-bleed approach the user
 * didn't like). On narrower screens the boxed content already reaches the
 * edges, so these side panels sit mostly or fully off-screen — nothing to
 * fix there.
 *
 * Illustrated (SVG), not a stock photo — same reasoning as HeroBackdrop:
 * no licensing question, nothing to load, and it echoes the same Himalayan
 * motif used in the hero rather than introducing a second visual language.
 * A soft trust-toned gradient wash sits under the ridge art so the margin
 * actually reads as designed rather than empty (the earlier version at 5%
 * opacity / 18vw was too faint to register as anything). Still `fixed`
 * (not `absolute`) so it never competes with foreground text/cards and
 * never affects page height/scroll.
 */
function Ridge({ flip = false }: { flip?: boolean }) {
  return (
    <svg
      className="h-full w-full"
      style={flip ? { transform: 'scaleX(-1)' } : undefined}
      viewBox="0 0 300 1000"
      preserveAspectRatio="xMinYMax slice"
      fill="none"
    >
      <path
        d="M-20 760 L60 620 L130 700 L210 560 L300 660 L300 1000 L-20 1000 Z"
        fill="var(--color-trust-700)"
        opacity="0.5"
      />
      <path
        d="M-20 860 L90 760 L170 830 L260 730 L300 780 L300 1000 L-20 1000 Z"
        fill="var(--color-trust-700)"
        opacity="0.8"
      />
      <path d="M210 560 L232 592 L188 598 Z" fill="var(--color-stone-50)" opacity="0.7" />
    </svg>
  )
}

export function PageBackdrop() {
  return (
    <div className="pointer-events-none fixed inset-0 -z-10 overflow-hidden" aria-hidden="true">
      <div className="absolute inset-y-0 left-0 w-[26vw] max-w-[420px] bg-gradient-to-r from-trust-100/70 via-trust-100/25 to-transparent">
        <div className="h-full w-full opacity-[0.12]">
          <Ridge />
        </div>
      </div>
      <div className="absolute inset-y-0 right-0 w-[26vw] max-w-[420px] bg-gradient-to-l from-trust-100/70 via-trust-100/25 to-transparent">
        <div className="h-full w-full opacity-[0.12]">
          <Ridge flip />
        </div>
      </div>
    </div>
  )
}
