/**
 * JS-side mirror of the CSS design tokens in `src/index.css` (`@theme` block).
 * Use these only where a raw value is unavoidable — Leaflet marker colors,
 * chart series, canvas — everywhere else prefer the matching Tailwind class
 * (e.g. `bg-trust-700`, `text-accent-600`) so there is a single source of truth.
 */
export const colors = {
  stone50: '#faf9f6',
  stone100: '#f0eee8',
  stone200: '#e2ded4',

  ink900: '#211f1a',
  ink700: '#59564d',
  trust700: '#1f4b3f',
  trust600: '#2c6753',
  trust100: '#e4ede8',

  accent600: '#bf5f2c',
  accent500: '#d67c40',
  accent100: '#f8e6d8',

  link600: '#1f4b3f',
  link700: '#163829',

  danger600: '#dc2626',
  danger100: '#fee2e2',
  warning600: '#d97706',
  warning100: '#fef3c7',
  success600: '#15803d',
  success100: '#dcfce7',
} as const

/** Formats a NPR amount, e.g. 4500000 -> "Rs 45,00,000" (Nepali digit grouping). */
export function formatNpr(amount: number): string {
  const formatted = new Intl.NumberFormat('en-IN').format(Math.round(amount))
  return `Rs ${formatted}`
}

/** Compact NPR for cards/lists, e.g. 4500000 -> "Rs 45 Lakh", 25000000 -> "Rs 2.5 Crore". */
export function formatNprCompact(amount: number): string {
  const abs = Math.abs(amount)
  if (abs >= 1_00_00_000) return `Rs ${trim(amount / 1_00_00_000)} Crore`
  if (abs >= 1_00_000) return `Rs ${trim(amount / 1_00_000)} Lakh`
  if (abs >= 1_000) return `Rs ${trim(amount / 1_000)}K`
  return formatNpr(amount)
}

function trim(value: number): string {
  return value.toFixed(value % 1 === 0 ? 0 : 1)
}

/** Compact view/count display, e.g. 950 -> "950", 12400 -> "12.4K", 2000000 -> "2M". */
export function formatCompactCount(count: number): string {
  if (count >= 1_000_000) return `${trim(count / 1_000_000)}M`
  if (count >= 1_000) return `${trim(count / 1_000)}K`
  return String(count)
}
