import { Link } from 'react-router-dom'
import { Newspaper, Plus } from 'lucide-react'
import { useAdminBlogPosts } from '../../lib/api/blog'
import { AdminPageHeader } from '../../components/admin/AdminPageHeader'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { ButtonLink } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'

export function Blog() {
  const { data, isPending, isError, refetch } = useAdminBlogPosts()

  return (
    <div className="flex flex-col gap-6">
      <AdminPageHeader
        icon={Newspaper}
        title="Blog"
        description="Real content pages a search engine can rank — drafts stay hidden until published."
        action={
          <ButtonLink to="/admin/blog/new">
            <Plus className="h-4 w-4" /> New post
          </ButtonLink>
        }
      />

      {isPending && <PropertyGridSkeleton count={4} />}
      {isError && <ErrorState onRetry={refetch} />}
      {!isPending && !isError && data?.length === 0 && (
        <EmptyState title="No posts yet" description="Write your first post to get started." />
      )}

      <div className="flex flex-col gap-2">
        {data?.map((post) => (
          <Link key={post.id} to={`/admin/blog/${post.id}`}>
            <Card className="flex flex-wrap items-center justify-between gap-3 p-3 transition-shadow hover:shadow-md">
              <div className="flex items-center gap-3">
                {post.cover_image_url ? (
                  <img src={post.cover_image_url} alt="" className="h-12 w-12 shrink-0 rounded-lg object-cover" />
                ) : (
                  <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg bg-stone-100 text-ink-700/40">
                    <Newspaper className="h-5 w-5" />
                  </div>
                )}
                <div>
                  <p className="font-medium text-ink-900">{post.title}</p>
                  <p className="text-xs text-ink-700/60">{post.author ?? 'Unknown author'}</p>
                </div>
              </div>
              <Badge tone={post.status === 'published' ? 'trust' : 'warning'}>{post.status}</Badge>
            </Card>
          </Link>
        ))}
      </div>
    </div>
  )
}
