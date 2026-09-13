/**
 * JS-side mirror of the CSS design tokens in `src/index.css` (`@theme` block).
 * Use these only where a raw value is unavoidable — Leaflet marker colors,
 * chart series, canvas — everywhere else prefer the matching Tailwind class
 * (e.g. `bg-trust-700`, `text-accent-600`) so there is a single source of truth.
 */
export const colors = {
  stone50: '#f8fafc',
  stone100: '#f1f5f9',
  stone200: '#e2e8f0',

  ink900: '#0f172a',
  ink700: '#334155',
  trust700: '#0f4c3a',
  trust600: '#3f7061',
  trust100: '#e7edeb',

  accent600: '#059669',
  accent500: '#10b981',
  accent100: '#d1fae5',

  link600: '#0f4c3a',
  link700: '#0d4131',

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
