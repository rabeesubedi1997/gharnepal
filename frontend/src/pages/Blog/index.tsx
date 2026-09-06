import { useState } from 'react'
import { Link } from 'react-router-dom'
import { Newspaper } from 'lucide-react'
import { useBlogPosts } from '../../lib/api/blog'
import { useStaticPageSeo } from '../../lib/api/seo'
import { SeoHead } from '../../components/seo/SeoHead'
import { Card } from '../../components/ui/Card'
import { Button } from '../../components/ui/Button'
import { EmptyState } from '../../components/ui/EmptyState'
import { ErrorState } from '../../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../../components/ui/Skeleton'

export function BlogList() {
  const [page, setPage] = useState(1)
  const { data, isPending, isError, refetch } = useBlogPosts(page)
  const { data: seo } = useStaticPageSeo('blog')

  return (
    <div className="flex flex-col gap-6">
      <SeoHead seo={seo} />
      <div>
        <h1 className="font-display text-2xl font-semibold text-ink-900">Blog</h1>
        <p className="mt-1 text-sm text-ink-700/70">Guides, market updates, and practical advice for property in Nepal.</p>
      </div>

      {isPending && <PropertyGridSkeleton count={6} />}
      {isError && <ErrorState onRetry={refetch} description="Couldn't load posts right now." />}
      {!isPending && !isError && data?.data.length === 0 && (
        <EmptyState icon={<Newspaper className="h-8 w-8" aria-hidden="true" />} title="No posts yet" description="Check back soon." />
      )}

      {!isPending && !isError && data && data.data.length > 0 && (
        <>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {data.data.map((post) => (
              <Link key={post.id} to={`/blog/${post.slug}`}>
                <Card className="flex h-full flex-col overflow-hidden transition-shadow hover:shadow-md">
                  <div className="aspect-[16/9] w-full overflow-hidden bg-stone-100">
                    {post.cover_image_url ? (
                      <img src={post.cover_image_url} alt={post.title} className="h-full w-full object-cover" />
                    ) : (
                      <div className="flex h-full w-full items-center justify-center text-ink-700/30">
                        <Newspaper className="h-8 w-8" aria-hidden="true" />
                      </div>
                    )}
                  </div>
                  <div className="flex flex-1 flex-col gap-1.5 p-3">
                    <h2 className="line-clamp-2 font-display text-base font-semibold text-ink-900">{post.title}</h2>
                    {post.excerpt && <p className="line-clamp-2 text-sm text-ink-700/70">{post.excerpt}</p>}
                    <p className="mt-auto pt-1 text-xs text-ink-700/50">
                      {post.author ?? 'Ghar Nepal'} · {post.published_at && new Date(post.published_at).toLocaleDateString()}
                    </p>
                  </div>
                </Card>
              </Link>
            ))}
          </div>

          {data.meta.last_page > 1 && (
            <div className="mt-2 flex justify-center gap-2">
              <Button variant="outline" size="sm" disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>
                Previous
              </Button>
              <span className="flex items-center px-2 text-sm text-ink-700/70">
                Page {data.meta.current_page} of {data.meta.last_page}
              </span>
              <Button variant="outline" size="sm" disabled={page >= data.meta.last_page} onClick={() => setPage((p) => p + 1)}>
                Next
              </Button>
            </div>
          )}
        </>
      )}
    </div>
  )
}
