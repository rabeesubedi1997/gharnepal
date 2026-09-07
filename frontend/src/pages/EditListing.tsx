import { useEffect, useState } from 'react'
import { useParams } from 'react-router-dom'
import { Pencil } from 'lucide-react'
import { useOwnerListing, useUpdateListing } from '../lib/api/listings'
import { useAmenities } from '../lib/api/amenities'
import { getErrorMessage } from '../lib/api/errors'
import { Card } from '../components/ui/Card'
import { Button, ButtonLink } from '../components/ui/Button'
import { Input, Select } from '../components/ui/Input'
import { ErrorState } from '../components/ui/ErrorState'
import { Skeleton } from '../components/ui/Skeleton'

export function EditListing() {
  const { id } = useParams<{ id: string }>()
  const listingId = id ? Number(id) : undefined
  const { data: listing, isPending, isError, refetch } = useOwnerListing(listingId)
  const { data: amenities } = useAmenities()
  const update = useUpdateListing()

  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [price, setPrice] = useState('')
  const [pricePeriod, setPricePeriod] = useState<'total' | 'monthly' | ''>('')
  const [negotiable, setNegotiable] = useState(false)
  const [availabilityDate, setAvailabilityDate] = useState('')
  const [amenityIds, setAmenityIds] = useState<number[]>([])
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Seed the form once the listing loads — an editable draft copy, not a
  // live-bound view of the fetched data.
  useEffect(() => {
    if (!listing) return
    setTitle(listing.title)
    setDescription(listing.description ?? '')
    setPrice(String(listing.price))
    setPricePeriod(listing.price_period ?? '')
    setNegotiable(listing.negotiable)
    setAvailabilityDate(listing.availability_date ?? '')
    setAmenityIds(listing.amenities.map((a) => a.id))
  }, [listing])

  const toggleAmenity = (amenityId: number) => {
    setAmenityIds((ids) => (ids.includes(amenityId) ? ids.filter((i) => i !== amenityId) : [...ids, amenityId]))
  }

  const handleSave = () => {
    if (!listingId) return
    setError(null)
    setSaved(false)
    update.mutate(
      {
        listingId,
        input: {
          title: title.trim(),
          description: description.trim() || undefined,
          price: Number(price),
          price_period: pricePeriod || undefined,
          negotiable,
          availability_date: availabilityDate || undefined,
          amenity_ids: amenityIds,
        },
      },
      {
        onSuccess: () => setSaved(true),
        onError: (e) => setError(getErrorMessage(e)),
      },
    )
  }

  if (isPending) {
    return (
      <div className="mx-auto flex max-w-2xl flex-col gap-4">
        <Skeleton className="h-8 w-48" />
        <Skeleton className="h-96 w-full" />
      </div>
    )
  }

  if (isError || !listing) {
    return <ErrorState title="Couldn't load this listing" onRetry={refetch} />
  }

  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-6">
      <div>
        <h1 className="flex items-center gap-2 font-display text-2xl font-semibold text-ink-900">
          <Pencil className="h-6 w-6 text-trust-700" /> Edit listing
        </h1>
        <p className="mt-1 text-sm text-ink-700/70">
          Property details (address, area, bedrooms) are fixed after posting — this edits the listing itself.
        </p>
      </div>

      <Card className="flex flex-col gap-4 p-4">
        <Input label="Listing title" value={title} onChange={(e) => setTitle(e.target.value)} />

        <div className="grid grid-cols-2 gap-4">
          <Input label="Price (NPR)" type="number" min="1" value={price} onChange={(e) => setPrice(e.target.value)} />
          {listing.purpose === 'rent' && (
            <Select label="Price period" value={pricePeriod} onChange={(e) => setPricePeriod(e.target.value as 'total' | 'monthly')}>
              <option value="">Select</option>
              <option value="monthly">Per month</option>
              <option value="total">Total</option>
            </Select>
          )}
        </div>

        <label className="flex items-center gap-2 text-sm text-ink-900">
          <input
            type="checkbox"
            checked={negotiable}
            onChange={(e) => setNegotiable(e.target.checked)}
            className="h-4 w-4 rounded border-stone-200 text-trust-700 focus:ring-trust-700"
          />
          Price is negotiable
        </label>

        <Input
          label="Available from (optional)"
          type="date"
          value={availabilityDate}
          onChange={(e) => setAvailabilityDate(e.target.value)}
        />

        <div className="flex flex-col gap-1.5">
          <label className="text-sm font-medium text-ink-900">Description</label>
          <textarea
            rows={5}
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            className="rounded-lg border border-stone-200 bg-white px-3 py-2 text-sm text-ink-900 focus:outline-none focus:ring-2 focus:ring-trust-700"
          />
        </div>

        <div>
          <p className="mb-2 text-sm font-medium text-ink-900">Amenities</p>
          <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
            {amenities?.map((amenity) => (
              <label
                key={amenity.id}
                className="flex items-center gap-2 rounded-lg border border-stone-200 px-3 py-2 text-sm text-ink-900 hover:bg-stone-100"
              >
                <input
                  type="checkbox"
                  checked={amenityIds.includes(amenity.id)}
                  onChange={() => toggleAmenity(amenity.id)}
                  className="h-4 w-4 rounded border-stone-200 text-trust-700 focus:ring-trust-700"
                />
                {amenity.name}
              </label>
            ))}
          </div>
        </div>

        {error && <p className="text-sm text-danger-600">{error}</p>}
        {saved && <p className="text-sm text-success-600">Saved.</p>}

        <div className="flex justify-between">
          <ButtonLink to="/dashboard" variant="outline">
            Back to dashboard
          </ButtonLink>
          <Button isLoading={update.isPending} disabled={!title.trim() || !price} onClick={handleSave}>
            Save changes
          </Button>
        </div>
      </Card>
    </div>
  )
}
