import { useState } from 'react'
import { Folder, FolderPlus, Heart, Share2, Trash2 } from 'lucide-react'
import { clsx } from 'clsx'
import {
  useCreateFavoriteCollection,
  useDeleteFavoriteCollection,
  useFavoriteCollections,
  useFavoritesByCollection,
  useMoveFavoriteToCollection,
} from '../lib/api/favoriteCollections'
import { PropertyCard } from '../components/property/PropertyCard'
import { PropertyGridSkeleton } from '../components/ui/Skeleton'
import { EmptyState } from '../components/ui/EmptyState'
import { ErrorState } from '../components/ui/ErrorState'
import { Button, ButtonLink } from '../components/ui/Button'
import { Modal } from '../components/ui/Modal'
import { Input } from '../components/ui/Input'
import { useToast } from '../components/ui/Toast'

export function Saved() {
  const [selected, setSelected] = useState<number | null>(null)
  const [createOpen, setCreateOpen] = useState(false)
  const [newName, setNewName] = useState('')

  const toast = useToast()
  const { data: collections } = useFavoriteCollections()
  const { data: listings, isPending, isError, refetch } = useFavoritesByCollection(selected)
  const createCollection = useCreateFavoriteCollection()
  const deleteCollection = useDeleteFavoriteCollection()
  const moveFavorite = useMoveFavoriteToCollection()

  const selectedCollection = collections?.find((c) => c.id === selected) ?? null

  const handleCreate = () => {
    if (!newName.trim()) return
    createCollection.mutate(newName.trim(), {
      onSuccess: (collection) => {
        setCreateOpen(false)
        setNewName('')
        setSelected(collection.id)
        toast.success(`Created "${collection.name}"`)
      },
      onError: () => toast.error("Couldn't create that collection."),
    })
  }

  const handleShare = async (token: string) => {
    const url = `${window.location.origin}/collections/${token}`
    if (navigator.share) {
      try {
        await navigator.share({ title: 'A shared property collection', url })
        return
      } catch {
        // user cancelled the share sheet — fall through to clipboard copy
      }
    }
    await navigator.clipboard.writeText(url)
    toast.success('Share link copied to clipboard')
  }

  const handleDelete = (id: number, name: string) => {
    if (!window.confirm(`Delete "${name}"? Saved listings inside it move back to "All saved" — nothing is un-saved.`)) return
    deleteCollection.mutate(id, {
      onSuccess: () => {
        if (selected === id) setSelected(null)
        toast.success(`Deleted "${name}"`)
      },
    })
  }

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h1 className="font-display text-2xl font-semibold text-ink-900">Saved properties</h1>
        <Button variant="outline" size="sm" onClick={() => setCreateOpen(true)}>
          <FolderPlus className="h-4 w-4" /> New collection
        </Button>
      </div>

      <div className="flex flex-wrap gap-2">
        <button
          type="button"
          onClick={() => setSelected(null)}
          className={clsx(
            'rounded-full px-3 py-1.5 text-sm font-medium transition-colors',
            selected === null ? 'bg-trust-700 text-white' : 'bg-stone-100 text-ink-700 hover:bg-stone-200',
          )}
        >
          All saved
        </button>
        {collections?.map((collection) => (
          <div
            key={collection.id}
            className={clsx(
              'group flex items-center gap-1 rounded-full pl-3 pr-1.5 py-1 text-sm font-medium transition-colors',
              selected === collection.id ? 'bg-trust-700 text-white' : 'bg-stone-100 text-ink-700 hover:bg-stone-200',
            )}
          >
            <button type="button" onClick={() => setSelected(collection.id)} className="flex items-center gap-1.5 py-0.5">
              <Folder className="h-3.5 w-3.5" aria-hidden="true" />
              {collection.name}
              <span className="opacity-70">({collection.listings_count})</span>
            </button>
            <button
              type="button"
              onClick={() => handleShare(collection.share_token)}
              aria-label={`Share ${collection.name}`}
              title="Copy share link"
              className={clsx('rounded-full p-1', selected === collection.id ? 'hover:bg-white/20' : 'hover:bg-stone-300/60')}
            >
              <Share2 className="h-3 w-3" aria-hidden="true" />
            </button>
            <button
              type="button"
              onClick={() => handleDelete(collection.id, collection.name)}
              aria-label={`Delete ${collection.name}`}
              title="Delete collection"
              className={clsx('rounded-full p-1', selected === collection.id ? 'hover:bg-white/20' : 'hover:bg-stone-300/60')}
            >
              <Trash2 className="h-3 w-3" aria-hidden="true" />
            </button>
          </div>
        ))}
      </div>

      {isPending && <PropertyGridSkeleton count={6} />}
      {isError && <ErrorState onRetry={refetch} />}

      {!isPending && !isError && listings?.length === 0 && (
        <EmptyState
          icon={<Heart className="h-10 w-10" aria-hidden="true" />}
          title={selectedCollection ? `No listings in "${selectedCollection.name}" yet` : 'No saved properties yet'}
          description={
            selectedCollection
              ? 'Move a saved listing here using the "Move to…" menu on its card.'
              : 'Tap the heart icon on any listing to save it here for later.'
          }
          action={<ButtonLink to="/search" size="sm">Browse properties</ButtonLink>}
        />
      )}

      {!isPending && !isError && listings && listings.length > 0 && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {listings.map((listing) => (
            <div key={listing.id} className="flex flex-col gap-2">
              {/* PropertyCard's own heart toggle (top-right on every card)
                  already handles un-saving entirely — tapping it again
                  unfavorites regardless of which collection it's in. */}
              <PropertyCard listing={listing} />
              <label className="flex items-center gap-1.5 text-xs text-ink-700/70">
                Move to…
                {/* Deliberately always reset to the placeholder rather than
                    reflect the listing's current collection — the summary
                    this list renders from doesn't carry that per-card, so
                    this control is a one-shot action, not a state toggle. */}
                <select
                  value=""
                  onChange={(e) => {
                    const value = e.target.value
                    if (!value) return
                    moveFavorite.mutate(
                      { listingId: listing.id, collectionId: value === 'none' ? null : Number(value) },
                      { onError: () => toast.error("Couldn't move that listing.") },
                    )
                  }}
                  className="rounded-md border border-stone-200 bg-white px-2 py-1 text-xs text-ink-900 focus:outline-none focus:ring-2 focus:ring-trust-700"
                >
                  <option value="" disabled>
                    Choose a collection
                  </option>
                  <option value="none">All saved (no collection)</option>
                  {collections?.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.name}
                    </option>
                  ))}
                </select>
              </label>
            </div>
          ))}
        </div>
      )}

      <Modal open={createOpen} onClose={() => setCreateOpen(false)} title="New collection">
        <div className="flex flex-col gap-4">
          <Input
            label="Collection name"
            placeholder="e.g. Family homes near school"
            value={newName}
            onChange={(e) => setNewName(e.target.value)}
          />
          <div className="flex justify-end gap-2">
            <Button variant="outline" onClick={() => setCreateOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handleCreate} isLoading={createCollection.isPending} disabled={!newName.trim()}>
              Create
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  )
}
