import { useEffect } from 'react'
import { useBranding } from '../../lib/api/branding'

/**
 * Applies the admin-configured favicon live, the moment it changes — no
 * rebuild/redeploy needed (see Admin > Branding). Renders nothing.
 *
 * Deliberately does NOT touch <title> — every page already sets its own via
 * <SeoHead>, and a second writer here would just fight it. Site name shown
 * in the Header/Footer reads useBranding() directly where it's displayed.
 */
export function BrandingSync() {
  const { data: branding } = useBranding()

  useEffect(() => {
    if (!branding?.favicon_url) return
    let link = document.querySelector<HTMLLinkElement>("link[rel~='icon']")
    if (!link) {
      link = document.createElement('link')
      link.rel = 'icon'
      document.head.appendChild(link)
    }
    link.href = branding.favicon_url
  }, [branding?.favicon_url])

  return null
}
