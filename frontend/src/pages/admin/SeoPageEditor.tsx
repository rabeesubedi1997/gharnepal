import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { ExternalLink, RotateCcw, Search as SearchIcon, Trash2 } from 'lucide-react'
import {
  useAdminSeoPage,
  useDiscardScan,
  useResetSeoPage,
  useSaveSeoPage,
  useScanCompetitor,
  type CompetitorScan,
} from '../../lib/api/seo'
import { getErrorMessage } from '../../lib/api/errors'
import { Card } from '../../components/ui/Card'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { Input } from '../../components/ui/Input'
import { ErrorState } from '../../components/ui/ErrorState'
import { Skeleton } from '../../components/ui/Skeleton'

const textareaClass =
  'rounded-lg border border-stone-200 px-3 py-2 text-sm text-ink-900 focus:outline-none focus:ring-2 focus:ring-trust-700'

export function SeoPageEditor() {
  const { key: encodedKey } = useParams<{ key: string }>()
  const key = decodeURIComponent(encodedKey ?? '')

  const { data, isPending, isError, refetch } = useAdminSeoPage(key)
  const save = useSaveSeoPage(key)
  const reset = useResetSeoPage(key)
  const scan = useScanCompetitor(key)
  const discardScan = useDiscardScan(key)

  const [metaTitle, setMetaTitle] = useState('')
  const [metaDescription, setMetaDescription] = useState('')
  const [metaKeywords, setMetaKeywords] = useState('')
  const [ogImageUrl, setOgImageUrl] = useState('')
  const [canonicalPath, setCanonicalPath] = useState('')
  const [robotsIndex, setRobotsIndex] = useState(true)
  const [robotsFollow, setRobotsFollow] = useState(true)
  const [saveError, setSaveError] = useState<string | null>(null)
  const [savedNotice, setSavedNotice] = useState<'draft' | 'published' | null>(null)

  const [scanUrl, setScanUrl] = useState('')
  const [scanError, setScanError] = useState<string | null>(null)

  useEffect(() => {
    if (!data) return
    const o = data.override
    setMetaTitle(o?.meta_title ?? '')
    setMetaDescription(o?.meta_description ?? '')
    setMetaKeywords(o?.meta_keywords ?? '')
    setOgImageUrl(o?.og_image_url ?? '')
    setCanonicalPath(o?.canonical_path ?? '')
    setRobotsIndex(o?.robots_index ?? true)
    setRobotsFollow(o?.robots_follow ?? true)
  }, [data])

  if (isPending) {
    return (
      <div className="flex flex-col gap-4">
        <Skeleton className="h-8 w-64" />
        <Skeleton className="h-64 w-full" />
      </div>
    )
  }

  if (isError || !data) {
    return <ErrorState title="Page not found" description="This page may no longer exist." onRetry={refetch} />
  }

  const { effective } = data

  const handleSave = (status: 'draft' | 'published') => {
    setSaveError(null)
    setSavedNotice(null)
    save.mutate(
      {
        meta_title: metaTitle.trim() || null,
        meta_description: metaDescription.trim() || null,
        meta_keywords: metaKeywords.trim() || null,
        og_image_url: ogImageUrl.trim() || null,
        canonical_path: canonicalPath.trim() || null,
        robots_index: robotsIndex,
        robots_follow: robotsFollow,
        status,
      },
      {
        onSuccess: () => setSavedNotice(status),
        onError: (e) => setSaveError(getErrorMessage(e)),
      },
    )
  }

  const handleScan = () => {
    setScanError(null)
    if (!scanUrl.trim()) return
    scan.mutate(scanUrl.trim(), {
      onSuccess: () => setScanUrl(''),
      onError: (e) => setScanError(getErrorMessage(e)),
    })
  }

  // What a viewer would actually see right now if the form were published as-is.
  const previewTitle = metaTitle.trim() || effective.title
  const previewDescription = metaDescription.trim() || effective.description || ''

  return (
    <div className="flex flex-col gap-6">
      <div>
        <Link to="/admin/seo" className="text-sm text-link-600 hover:text-link-700">
          &larr; All pages
        </Link>
        <div className="mt-1 flex flex-wrap items-center justify-between gap-2">
          <div>
            <h1 className="font-display text-2xl font-semibold text-ink-900">{effective.label}</h1>
            <p className="flex items-center gap-1 text-xs text-ink-700/60">
              {effective.canonical_url} <ExternalLink className="h-3 w-3" aria-hidden="true" />
            </p>
          </div>
          {data.override && (
            <Badge tone={data.override.status === 'published' ? 'trust' : 'warning'}>
              {data.override.status === 'published' ? 'Published override live' : 'Draft — not live yet'}
            </Badge>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-[1fr_320px]">
        <div className="flex flex-col gap-4">
          <Card className="flex flex-col gap-3 p-4">
            <h2 className="font-display text-base font-semibold text-ink-900">Page content</h2>

            <Input
              label="Meta title"
              placeholder={effective.title}
              value={metaTitle}
              onChange={(e) => setMetaTitle(e.target.value)}
              hint={`${metaTitle.length}/70 characters recommended. Leave blank to use the auto-generated default shown as placeholder.`}
            />

            <label className="flex flex-col gap-1.5">
              <span className="text-sm font-medium text-ink-900">Meta description</span>
              <textarea
                rows={3}
                placeholder={effective.description ?? ''}
                value={metaDescription}
                onChange={(e) => setMetaDescription(e.target.value)}
                className={textareaClass}
              />
              <span className="text-sm text-ink-700/70">{metaDescription.length}/160 characters recommended.</span>
            </label>

            <Input
              label="Meta keywords (optional, comma-separated)"
              value={metaKeywords}
              onChange={(e) => setMetaKeywords(e.target.value)}
            />

            <Input
              label="Social share image URL (optional)"
              placeholder={effective.og_image ?? 'Uses the page\'s own cover image if left blank'}
              value={ogImageUrl}
              onChange={(e) => setOgImageUrl(e.target.value)}
            />

            <Input
              label="Canonical path override (optional)"
              placeholder={new URL(effective.canonical_url).pathname}
              value={canonicalPath}
              onChange={(e) => setCanonicalPath(e.target.value)}
              hint="Only set this if this page should be treated as a duplicate of another path."
            />

            <div className="flex flex-wrap gap-4 pt-1">
              <label className="flex items-center gap-2 text-sm text-ink-900">
                <input type="checkbox" checked={robotsIndex} onChange={(e) => setRobotsIndex(e.target.checked)} />
                Allow search engines to index this page
              </label>
              <label className="flex items-center gap-2 text-sm text-ink-900">
                <input type="checkbox" checked={robotsFollow} onChange={(e) => setRobotsFollow(e.target.checked)} />
                Allow following links on this page
              </label>
            </div>

            {saveError && <p className="text-sm text-danger-600">{saveError}</p>}
            {savedNotice && (
              <p className="text-sm text-trust-700">
                {savedNotice === 'published' ? 'Published — this is now live.' : 'Saved as a draft — not live yet.'}
              </p>
            )}

            <div className="flex flex-wrap items-center gap-2 pt-1">
              <Button isLoading={save.isPending} onClick={() => handleSave('published')}>
                Publish
              </Button>
              <Button variant="outline" isLoading={save.isPending} onClick={() => handleSave('draft')}>
                Save as draft
              </Button>
              {data.override && (
                <Button
                  variant="ghost"
                  onClick={() => reset.mutate()}
                  isLoading={reset.isPending}
                  className="text-danger-600 hover:bg-danger-100/40"
                >
                  <RotateCcw className="h-4 w-4" /> Reset to auto-generated default
                </Button>
              )}
            </div>
          </Card>

          <Card className="flex flex-col gap-3 p-4">
            <div>
              <h2 className="font-display text-base font-semibold text-ink-900">Competitor research</h2>
              <p className="text-sm text-ink-700/70">
                Scan a competitor's page for its title, description, headings, and top keywords — for inspiration
                only. Nothing is copied or published automatically; write your own version above and publish when
                ready.
              </p>
            </div>

            <div className="flex flex-wrap items-end gap-2">
              <Input
                label="Competitor page URL"
                placeholder="https://example.com/listings/some-property"
                value={scanUrl}
                onChange={(e) => setScanUrl(e.target.value)}
                className="min-w-[16rem] flex-1"
              />
              <Button isLoading={scan.isPending} disabled={!scanUrl.trim()} onClick={handleScan}>
                <SearchIcon className="h-4 w-4" /> Scan
              </Button>
            </div>
            {scanError && <p className="text-sm text-danger-600">{scanError}</p>}

            {data.scans.length === 0 ? (
              <p className="text-sm text-ink-700/60">No scans yet.</p>
            ) : (
              <div className="flex flex-col gap-3">
                {data.scans.map((s) => (
                  <ScanCard
                    key={s.id}
                    scan={s}
                    onUseTitle={() => s.scanned_title && setMetaTitle(s.scanned_title)}
                    onUseDescription={() => s.scanned_meta_description && setMetaDescription(s.scanned_meta_description)}
                    onDiscard={() => discardScan.mutate(s.id)}
                    isDiscarding={discardScan.isPending}
                  />
                ))}
              </div>
            )}
          </Card>
        </div>

        <div className="flex flex-col gap-4">
          <Card className="flex flex-col gap-2 p-4">
            <h2 className="text-sm font-semibold text-ink-700/70">Search result preview</h2>
            <div className="rounded-lg border border-stone-100 p-3">
              <p className="truncate text-xs text-success-600">{effective.canonical_url}</p>
              <p className="truncate text-base text-link-600">{previewTitle}</p>
              <p className="line-clamp-2 text-sm text-ink-700/70">{previewDescription}</p>
            </div>
          </Card>

          <Card className="flex flex-col gap-2 p-4">
            <h2 className="text-sm font-semibold text-ink-700/70">Social share preview</h2>
            <div className="overflow-hidden rounded-lg border border-stone-100">
              {(ogImageUrl.trim() || effective.og_image) && (
                <img src={ogImageUrl.trim() || effective.og_image!} alt="" className="h-32 w-full object-cover" />
              )}
              <div className="p-3">
                <p className="truncate text-xs uppercase text-ink-700/50">
                  {new URL(effective.canonical_url).host}
                </p>
                <p className="truncate text-sm font-medium text-ink-900">{previewTitle}</p>
                <p className="line-clamp-2 text-xs text-ink-700/70">{previewDescription}</p>
              </div>
            </div>
          </Card>
        </div>
      </div>
    </div>
  )
}

function ScanCard({
  scan,
  onUseTitle,
  onUseDescription,
  onDiscard,
  isDiscarding,
}: {
  scan: CompetitorScan
  onUseTitle: () => void
  onUseDescription: () => void
  onDiscard: () => void
  isDiscarding: boolean
}) {
  return (
    <div className="rounded-lg border border-stone-100 p-3">
      <div className="flex items-start justify-between gap-2">
        <p className="truncate text-xs text-ink-700/60">{scan.competitor_url}</p>
        <button
          type="button"
          aria-label="Discard scan"
          onClick={onDiscard}
          disabled={isDiscarding}
          className="shrink-0 rounded-md p-1 text-danger-600 hover:bg-danger-100/40"
        >
          <Trash2 className="h-3.5 w-3.5" />
        </button>
      </div>

      {scan.scanned_title && (
        <div className="mt-2 flex items-center justify-between gap-2">
          <p className="truncate text-sm font-medium text-ink-900">{scan.scanned_title}</p>
          <Button size="sm" variant="outline" onClick={onUseTitle}>
            Use title
          </Button>
        </div>
      )}
      {scan.scanned_meta_description && (
        <div className="mt-1 flex items-center justify-between gap-2">
          <p className="line-clamp-2 text-sm text-ink-700/70">{scan.scanned_meta_description}</p>
          <Button size="sm" variant="outline" onClick={onUseDescription}>
            Use description
          </Button>
        </div>
      )}
      {scan.scanned_headings.length > 0 && (
        <p className="mt-2 text-xs text-ink-700/60">
          <span className="font-medium">Headings:</span> {scan.scanned_headings.join(' · ')}
        </p>
      )}
      {scan.scanned_keywords.length > 0 && (
        <div className="mt-1 flex flex-wrap gap-1">
          {scan.scanned_keywords.slice(0, 8).map((k) => (
            <Badge key={k.word} tone="neutral">
              {k.word} ({k.count})
            </Badge>
          ))}
        </div>
      )}
    </div>
  )
}
