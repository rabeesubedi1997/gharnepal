/**
 * JS-side mirror of the CSS design tokens in `src/index.css` (`@theme` block).
 * Use these only where a raw value is unavoidable — Leaflet marker colors,
 * chart series, canvas — everywhere else prefer the matching Tailwind class
 * (e.g. `bg-trust-700`, `text-accent-600`) so there is a single source of truth.
 */
export const colors = {
  stone50: '#ffffff',
  stone100: '#f4f5f7',
  stone200: '#e2e5ea',

  ink900: '#1a1d21',
  ink700: '#4b5563',
  trust700: '#0074e4',
  trust600: '#1a86ee',
  trust100: '#e3f1fd',

  accent600: '#c2542d',
  accent500: '#d97b3f',
  accent100: '#fbe8d8',

  link600: '#0074e4',
  link700: '#005bb8',

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
