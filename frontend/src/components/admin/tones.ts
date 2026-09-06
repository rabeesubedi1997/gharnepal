/**
 * A small shared color language for the admin console — each nav section
 * (see AdminLayout's NAV_GROUPS) gets its own accent so the console reads as
 * considered/branded rather than one flat gray dashboard. Reused by
 * AdminPageHeader (per-page icon badge) and AdminLayout (nav dot + active
 * left-accent-bar), so a page's header always matches its own nav item.
 */
export type AdminTone = 'trust' | 'accent' | 'link' | 'warning' | 'success' | 'danger'

export const ADMIN_TONE_BADGE: Record<AdminTone, string> = {
  trust: 'bg-trust-100 text-trust-700',
  accent: 'bg-accent-100 text-accent-600',
  link: 'bg-link-100 text-link-700',
  warning: 'bg-warning-100 text-warning-600',
  success: 'bg-success-100 text-success-600',
  danger: 'bg-danger-100 text-danger-600',
}

export const ADMIN_TONE_DOT: Record<AdminTone, string> = {
  trust: 'bg-trust-700',
  accent: 'bg-accent-600',
  link: 'bg-link-600',
  warning: 'bg-warning-600',
  success: 'bg-success-600',
  danger: 'bg-danger-600',
}

export const ADMIN_TONE_ACTIVE_NAV: Record<AdminTone, string> = {
  trust: 'border-trust-700 bg-trust-100 text-trust-700',
  accent: 'border-accent-600 bg-accent-100 text-accent-600',
  link: 'border-link-600 bg-link-100 text-link-700',
  warning: 'border-warning-600 bg-warning-100 text-warning-600',
  success: 'border-success-600 bg-success-100 text-success-600',
  danger: 'border-danger-600 bg-danger-100 text-danger-600',
}
