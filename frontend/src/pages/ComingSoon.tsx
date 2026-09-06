import { Construction } from 'lucide-react'
import { EmptyState } from '../components/ui/EmptyState'
import { ButtonLink } from '../components/ui/Button'

/**
 * Honest placeholder for routes whose feature lands in a later build phase
 * (see the build plan) — not a dead link, just a truthful "not built yet".
 */
export function ComingSoon({ title }: { title: string }) {
  return (
    <EmptyState
      icon={<Construction className="h-10 w-10" aria-hidden="true" />}
      title={`${title} is on the way`}
      description="This part of Ghar Nepal is still being built. Check back soon."
      action={
        <ButtonLink to="/" variant="outline" size="sm">
          Back to home
        </ButtonLink>
      }
    />
  )
}
