import { useEffect, useRef, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { Newspaper, Trash2 } from 'lucide-react'
import {
  useAdminBlogPost,
  useCreateBlogPost,
  useDeleteBlogPost,
  useUpdateBlogPost,
} from '../../lib/api/blog'
import { getErrorMessage } from '../../lib/api/errors'
import { AdminPageHeader } from '../../components/admin/AdminPageHeader'
import { Card } from '../../components/ui/Card'
import { Button } from '../../components/ui/Button'
import { Input } from '../../components/ui/Input'
import { ErrorState } from '../../components/ui/ErrorState'
import { Skeleton } from '../../components/ui/Skeleton'

const textareaClass =
  'rounded-lg border border-stone-200 px-3 py-2 text-sm text-ink-900 focus:outline-none focus:ring-2 focus:ring-trust-700'

export function BlogEditor() {
  const { id } = useParams<{ id: string }>()
  const isNew = id === 'new'
  const postId = isNew || !id ? undefined : Number(id)
  const navigate = useNavigate()

  const { data: post, isPending, isError, refetch } = useAdminBlogPost(postId)
  const create = useCreateBlogPost()
  const update = useUpdateBlogPost()
  const remove = useDeleteBlogPost()

  const [title, setTitle] = useState('')
  const [excerpt, setExcerpt] = useState('')
  const [body, setBody] = useState('')
  const [coverImage, setCoverImage] = useState<File | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [saved, setSaved] = useState(false)
  const fileRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (!post) return
    setTitle(post.title)
    setExcerpt(post.excerpt ?? '')
    setBody(post.body)
  }, [post])

  if (!isNew && isPending) {
    return (
      <div className="flex flex-col gap-4">
        <Skeleton className="h-8 w-64" />
        <Skeleton className="h-96 w-full" />
      </div>
    )
  }

  if (!isNew && (isError || !post)) {
    return <ErrorState title="Post not found" onRetry={refetch} />
  }

  const handleSave = (status: 'draft' | 'published') => {
    setError(null)
    setSaved(false)

    const input = { title, excerpt: excerpt || undefined, body, status, cover_image: coverImage ?? undefined }

    if (isNew) {
      create.mutate(input, {
        onSuccess: (created) => navigate(`/admin/blog/${created.id}`, { replace: true }),
        onError: (e) => setError(getErrorMessage(e)),
      })
    } else if (postId) {
      update.mutate(
        { id: postId, ...input },
        {
          onSuccess: () => {
            setSaved(true)
            setCoverImage(null)
            if (fileRef.current) fileRef.current.value = ''
          },
          onError: (e) => setError(getErrorMessage(e)),
        },
      )
    }
  }

  const isSaving = create.isPending || update.isPending
  const currentCoverUrl = coverImage ? URL.createObjectURL(coverImage) : post?.cover_image_url

  return (
    <div className="flex flex-col gap-6">
      <div>
        <Link to="/admin/blog" className="text-sm text-link-600 hover:text-link-700">
          &larr; All posts
        </Link>
      </div>
      <AdminPageHeader
        icon={Newspaper}
        title={isNew ? 'New post' : 'Edit post'}
        description={isNew ? undefined : `Slug: /blog/${post?.slug}`}
      />

      <Card className="flex flex-col gap-3 p-4">
        <Input label="Title" value={title} onChange={(e) => setTitle(e.target.value)} />

        <label className="flex flex-col gap-1.5">
          <span className="text-sm font-medium text-ink-900">Excerpt (optional — used as the card summary and SEO description)</span>
          <textarea rows={2} maxLength={300} value={excerpt} onChange={(e) => setExcerpt(e.target.value)} className={textareaClass} />
        </label>

        <label className="flex flex-col gap-1.5">
          <span className="text-sm font-medium text-ink-900">Body</span>
          <textarea rows={16} value={body} onChange={(e) => setBody(e.target.value)} className={textareaClass} placeholder="Write the article here — line breaks are preserved as paragraphs." />
        </label>

        <label className="flex flex-col gap-1.5">
          <span className="text-sm font-medium text-ink-900">Cover image (optional)</span>
          {currentCoverUrl && <img src={currentCoverUrl} alt="" className="h-40 w-full rounded-lg object-cover" />}
          <input ref={fileRef} type="file" accept="image/jpeg,image/png,image/webp" onChange={(e) => setCoverImage(e.target.files?.[0] ?? null)} className="text-sm" />
        </label>

        {error && <p className="text-sm text-danger-600">{error}</p>}
        {saved && <p className="text-sm text-trust-700">Saved.</p>}

        <div className="flex flex-wrap items-center gap-2 pt-1">
          <Button isLoading={isSaving} disabled={!title.trim() || !body.trim()} onClick={() => handleSave('published')}>
            Publish
          </Button>
          <Button variant="outline" isLoading={isSaving} disabled={!title.trim() || !body.trim()} onClick={() => handleSave('draft')}>
            Save as draft
          </Button>
          {!isNew && postId && (
            <Button
              variant="ghost"
              className="ml-auto text-danger-600 hover:bg-danger-100/40"
              onClick={() => remove.mutate(postId, { onSuccess: () => navigate('/admin/blog') })}
              isLoading={remove.isPending}
            >
              <Trash2 className="h-4 w-4" /> Delete post
            </Button>
          )}
        </div>
      </Card>
    </div>
  )
}
