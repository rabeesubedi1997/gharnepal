import { Link, useParams } from 'react-router-dom'
import { useBlogPost } from '../../lib/api/blog'
import { SeoHead } from '../../components/seo/SeoHead'
import { ErrorState } from '../../components/ui/ErrorState'
import { Skeleton } from '../../components/ui/Skeleton'

export function BlogPostDetail() {
  const { slug } = useParams<{ slug: string }>()
  const { data: post, isPending, isError, refetch } = useBlogPost(slug)

  if (isPending) {
    return (
      <div className="mx-auto flex max-w-2xl flex-col gap-4">
        <Skeleton className="h-8 w-2/3" />
        <Skeleton className="h-64 w-full" />
        <Skeleton className="h-40 w-full" />
      </div>
    )
  }

  if (isError || !post) {
    return <ErrorState title="Post not found" description="This article may have been removed." onRetry={refetch} />
  }

  return (
    <article className="mx-auto flex max-w-2xl flex-col gap-4">
      <SeoHead seo={post.seo} />
      <Link to="/blog" className="text-sm text-link-600 hover:text-link-700">
        &larr; All posts
      </Link>

      <div>
        <h1 className="font-display text-3xl font-semibold text-ink-900">{post.title}</h1>
        <p className="mt-2 text-sm text-ink-700/60">
          {post.author ?? 'Ghar Nepal'} · {post.published_at && new Date(post.published_at).toLocaleDateString()}
        </p>
      </div>

      {post.cover_image_url && (
        <div className="aspect-[16/9] w-full overflow-hidden rounded-card bg-stone-100">
          <img src={post.cover_image_url} alt={post.title} className="h-full w-full object-cover" />
        </div>
      )}

      <div className="whitespace-pre-line text-base leading-relaxed text-ink-900">{post.body}</div>
    </article>
  )
}
