import { useEffect } from 'react'
import { useLocation } from 'react-router-dom'

/** React Router's client-side navigation never resets scroll position on its
 * own (unlike a real page load) — without this, navigating away from a
 * scrolled-down spot (the footer, the bottom of a long listing page, page 2
 * of search results, ...) lands on the new page still scrolled down, which
 * looks like the new page "opened at the footer". Reset on every route
 * change, app-wide. Deliberately keyed on `pathname` only (not `search`) —
 * changing filters/query params on the *same* page (e.g. /search?...)
 * shouldn't yank scroll back to top mid-browse. */
export function ScrollToTop() {
  const { pathname } = useLocation()

  useEffect(() => {
    window.scrollTo(0, 0)
  }, [pathname])

  return null
}
