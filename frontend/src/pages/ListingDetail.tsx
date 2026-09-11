import { useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { BedDouble, Calendar, CalendarPlus, Car, Eye, Flag, Heart, Layers, MapPin, MessageCircle, Phone, Ruler, Share2, ShowerHead, Sparkles, Star, Trash2 } from 'lucide-react'
import { useListingDetail, type ListingDetail as ListingDetailType } from '../lib/api/listings'
import { useDeleteRating, useListingRatings, useSubmitRating } from '../lib/api/ratings'
import { RatingStars } from '../components/property/RatingStars'
import { useAddFavorite, useFavorites, useRemoveFavorite } from '../lib/api/favorites'
import { useStartConversation } from '../lib/api/messaging'
import { useRequestViewing } from '../lib/api/viewingRequests'
import { useSubmitReport, type ReportReason } from '../lib/api/reports'
import { useCurrentUser } from '../lib/api/auth'
import { getErrorMessage } from '../lib/api/errors'
import { useRequireAuth } from '../components/auth/AuthGateProvider'
import { useToast } from '../components/ui/Toast'
import { formatCompactCount, formatNpr } from '../design-system/tokens'
import { Card } from '../components/ui/Card'
import { Button } from '../components/ui/Button'
import { Badge } from '../components/ui/Badge'
import { Modal } from '../components/ui/Modal'
import { ErrorState } from '../components/ui/ErrorState'
import { Skeleton } from '../components/ui/Skeleton'
import { clsx } from 'clsx'
import { MapView } from '../components/property/MapView'
import { PropertyGallery } from '../components/property/PropertyGallery'
import { AdSlot } from '../components/marketing/AdSlot'
import { PropertyCard } from '../components/property/PropertyCard'
import { LandDueDiligenceChecklist } from '../components/property/LandDueDiligenceChecklist'
import { useVerifyLandProfile, type LandProfile } from '../lib/api/landProfile'
import { TrustBadge } from '../components/trust/TrustBadge'
import { useClearTrustOverride, useSetTrustOverride, type TrustScore } from '../lib/api/trust'
import { SeoHead } from '../components/seo/SeoHead'

const PARKING_TYPE_LABEL: Record<string, string> = {
  car: 'Car',
  bike: 'Bike/scooter',
  both: 'Car & bike',
}

const CLOSED_STATUS_LABEL: Partial<Record<ListingDetailType['status'], string>> = {
  sold: 'Sold',
  rented: 'Rented',
}

export function ListingDetail() {
  const { slug } = useParams<{ slug: string }>()
  const { data: listing, isPending, isError, refetch } = useListingDetail(slug)
  const { data: user } = useCurrentUser()
  const requireAuth = useRequireAuth()
  const [copied, setCopied] = useState(false)
  const [messageOpen, setMessageOpen] = useState(false)
  const [viewingOpen, setViewingOpen] = useState(false)
  const [reportOpen, setReportOpen] = useState(false)

  const { data: favorites } = useFavorites(!!user)
  const addFavorite = useAddFavorite()
  const removeFavorite = useRemoveFavorite()
  const isFavorited = !!favorites?.data.some((f) => f.id === listing?.id)

  const handleShare = async () => {
    const url = window.location.href
    if (navigator.share) {
      try {
        await navigator.share({ title: listing?.title, url })
        return
      } catch {
        // user cancelled the share sheet — fall through to clipboard copy
      }
    }
    await navigator.clipboard.writeText(url)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  if (isPending) {
    return (
      <div className="flex flex-col gap-4">
        <Skeleton className="h-96 w-full" />
        <Skeleton className="h-8 w-1/2" />
        <Skeleton className="h-24 w-full" />
      </div>
    )
  }

  if (isError || !listing) {
    return <ErrorState title="Listing not found" description="It may have been removed or is no longer available." onRetry={refetch} />
  }

  const { property } = listing
  const images = property.media.filter((m) => m.type === 'image')
  const locationLabel = [
    property.address?.neighborhood?.name,
    property.address?.municipality?.name,
    property.address?.district?.name,
  ]
    .filter(Boolean)
    .join(', ')

  return (
    <div className="flex flex-col gap-6">
      <SeoHead seo={listing.seo} />
      <PropertyGallery images={images} title={listing.title} />

      <div className="grid grid-cols-1 gap-8 lg:grid-cols-[1fr_320px]">
        <div className="flex flex-col gap-6">
          <div>
            <div className="flex items-start justify-between gap-3">
              <div>
                <h1 className="font-display text-2xl font-semibold text-ink-900">{listing.title}</h1>
                <p className="mt-1 flex flex-wrap items-center gap-x-3 gap-y-1 text-sm text-ink-700/70">
                  {locationLabel && (
                    <span className="flex items-center gap-1">
                      <MapPin className="h-4 w-4" aria-hidden="true" /> {locationLabel}
                    </span>
                  )}
                  {listing.views_count > 0 && (
                    <span className="flex items-center gap-1 text-ink-700/50">
                      <Eye className="h-4 w-4" aria-hidden="true" /> {formatCompactCount(listing.views_count)} views
                    </span>
                  )}
                  <span className="text-ink-700/50" title="Mention this code when calling or messaging about this listing">
                    Ref: {listing.reference_code}
                  </span>
                </p>
                <div className="mt-1">
                  <RatingStars average={listing.rating.average} count={listing.rating.count} size="md" />
                </div>
                <div className="mt-2 flex flex-wrap items-center gap-2">
                  {CLOSED_STATUS_LABEL[listing.status] && (
                    <Badge tone="neutral">{CLOSED_STATUS_LABEL[listing.status]}</Badge>
                  )}
                  {listing.is_featured && (
                    <Badge tone="accent">
                      <Sparkles className="h-3 w-3" /> Featured{listing.featured_until && ` until ${new Date(listing.featured_until).toLocaleDateString()}`}
                    </Badge>
                  )}
                  {listing.trust && <TrustBadge trust={listing.trust} />}
                </div>
                {user?.roles.includes('admin') && (
                  <AdminTrustOverridePanel listingId={listing.id} trust={listing.trust} />
                )}
              </div>
              <div className="flex gap-1">
                <IconButton label="Share listing" onClick={handleShare}>
                  <Share2 className="h-4 w-4" />
                </IconButton>
                <Button
                  variant="ghost"
                  size="sm"
                  aria-label={isFavorited ? 'Remove from saved' : 'Save property'}
                  isLoading={addFavorite.isPending || removeFavorite.isPending}
                  onClick={() =>
                    requireAuth(() =>
                      isFavorited ? removeFavorite.mutate(listing.id) : addFavorite.mutate(listing.id),
                    )
                  }
                >
                  <Heart className={clsx('h-4 w-4', isFavorited && 'fill-accent-600 text-accent-600')} />
                </Button>
                <IconButton label="Report listing" onClick={() => requireAuth(() => setReportOpen(true))}>
                  <Flag className="h-4 w-4" />
                </IconButton>
              </div>
            </div>
            {copied && <p className="mt-1 text-xs text-trust-700">Link copied to clipboard</p>}

            <p className="mt-3 flex items-center gap-2 text-2xl font-semibold text-trust-700">
              {formatNpr(listing.price)}
              {listing.purpose === 'rent' && listing.price_period === 'monthly' && (
                <span className="text-sm font-normal text-ink-700/60"> / month</span>
              )}
              {listing.negotiable && <Badge tone="accent">Negotiable</Badge>}
            </p>
            {property.area.display && (
              <p className="mt-1 flex flex-wrap gap-x-3 gap-y-0.5 text-xs text-ink-700/60">
                <span>{formatNpr(listing.price / property.area.display.sqft)} / sq ft</span>
                {property.property_type === 'land' && (
                  <>
                    <span>{formatNpr(listing.price / property.area.display.aana)} / aana</span>
                    <span>{formatNpr(listing.price / property.area.display.ropani)} / ropani</span>
                    <span>{formatNpr(listing.price / property.area.display.kattha)} / kattha</span>
                    <span>{formatNpr(listing.price / property.area.display.dhur)} / dhur</span>
                  </>
                )}
              </p>
            )}
            {listing.price_history.length > 1 && (
              <PriceHistoryLine history={listing.price_history} />
            )}
          </div>

          <div className="grid grid-cols-2 gap-4 rounded-card border border-stone-200 p-4 sm:grid-cols-4">
            {property.bedrooms != null && <Fact icon={<BedDouble className="h-4 w-4" />} label="Bedrooms" value={property.bedrooms} />}
            {property.bathrooms != null && <Fact icon={<ShowerHead className="h-4 w-4" />} label="Bathrooms" value={property.bathrooms} />}
            {property.area.sqm != null && <Fact icon={<Ruler className="h-4 w-4" />} label="Area" value={`${Math.round(property.area.sqm)} m²`} />}
            {property.floors != null && <Fact icon={<Layers className="h-4 w-4" />} label="Floors" value={property.floors} />}
            {property.parking_spaces != null && property.parking_spaces > 0 && (
              <Fact
                icon={<Car className="h-4 w-4" />}
                label="Parking"
                value={`${property.parking_spaces}${PARKING_TYPE_LABEL[property.parking_type ?? ''] ? ` · ${PARKING_TYPE_LABEL[property.parking_type ?? '']}` : ''}`}
              />
            )}
            {listing.availability_date && (
              <Fact icon={<Calendar className="h-4 w-4" />} label="Available" value={listing.availability_date} />
            )}
          </div>

          {listing.description && (
            <div>
              <h2 className="mb-2 font-display text-lg font-semibold text-ink-900">Description</h2>
              <p className="whitespace-pre-line text-sm text-ink-700/80">{listing.description}</p>
            </div>
          )}

          <RatingsSection listingId={listing.id} myRating={listing.my_rating} requireAuth={requireAuth} />

          {listing.amenities.length > 0 && (
            <div>
              <h2 className="mb-2 font-display text-lg font-semibold text-ink-900">Amenities</h2>
              <div className="flex flex-wrap gap-2">
                {listing.amenities.map((a) => (
                  <Badge key={a.id} tone="neutral">{a.name}</Badge>
                ))}
              </div>
            </div>
          )}

          {property.property_type === 'land' && property.land_profile && (
            <div className="flex flex-col gap-2">
              <LandDueDiligenceChecklist profile={property.land_profile} />
              {user?.roles.includes('admin') && (
                <AdminLandVerificationPanel propertyId={property.id} current={property.land_profile.document_verification_status} />
              )}
            </div>
          )}

          {property.address?.lat && property.address?.lng && (
            <div>
              <h2 className="mb-2 font-display text-lg font-semibold text-ink-900">Location</h2>
              <MapView
                listings={[
                  {
                    id: listing.id,
                    slug: listing.slug,
                    reference_code: listing.reference_code,
                    title: listing.title,
                    price: listing.price,
                    purpose: listing.purpose,
                    price_period: listing.price_period,
                    currency: listing.currency,
                    negotiable: listing.negotiable,
                    status: listing.status,
                    property_type: property.property_type,
                    bedrooms: property.bedrooms,
                    bathrooms: property.bathrooms,
                    area_sqm: property.area.sqm,
                    cover_image_url: images[0]?.url ?? null,
                    location: { municipality: null, ward_number: null, neighborhood: null, lat: property.address.lat as unknown as number, lng: property.address.lng as unknown as number },
                    published_at: listing.published_at,
                    views_count: listing.views_count,
                    trust_score: listing.trust?.score ?? null,
                    is_featured: listing.is_featured,
                    rating: listing.rating,
                  },
                ]}
              />
            </div>
          )}
        </div>

        <div className="flex flex-col gap-4">
          <Card className="flex flex-col gap-3 p-4">
            <p className="text-sm text-ink-700/60">Posted by</p>
            <p className="font-medium text-ink-900">{listing.poster?.name ?? 'Ghar Nepal user'}</p>
            {listing.poster?.agency && (
              <Link to={`/agents/${listing.poster.agency.slug}`} className="text-xs font-medium text-trust-700 hover:underline">
                {listing.poster.agency.name} · Verified agency
              </Link>
            )}
            {listing.poster?.member_since && (
              <p className="text-xs text-ink-700/60">Member since {listing.poster.member_since}</p>
            )}
            <Button className="mt-1 w-full" onClick={() => requireAuth(() => setMessageOpen(true))}>
              <MessageCircle className="h-4 w-4" /> Message owner
            </Button>
            <Button variant="outline" className="w-full" onClick={() => requireAuth(() => setViewingOpen(true))}>
              <CalendarPlus className="h-4 w-4" /> Request a viewing
            </Button>
            {listing.poster?.whatsapp_url && (
              <a
                href={listing.poster.whatsapp_url}
                target="_blank"
                rel="noreferrer"
                className="flex h-10 w-full items-center justify-center gap-2 rounded-lg border border-success-600/40 text-sm font-medium text-success-600 hover:bg-success-100/40"
              >
                <Phone className="h-4 w-4" /> Message on WhatsApp
              </a>
            )}
          </Card>
          <AdSlot placement="listing_detail_sidebar" aspectClassName="aspect-square" />
        </div>
      </div>

      {listing.similar_listings.length > 0 && (
        <div>
          <h2 className="mb-3 font-display text-lg font-semibold text-ink-900">Similar nearby listings</h2>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {listing.similar_listings.map((s) => (
              <PropertyCard key={s.id} listing={s} />
            ))}
          </div>
        </div>
      )}

      <MessageModal open={messageOpen} onClose={() => setMessageOpen(false)} listingId={listing.id} />
      <ViewingModal open={viewingOpen} onClose={() => setViewingOpen(false)} listingId={listing.id} />
      <ReportModal open={reportOpen} onClose={() => setReportOpen(false)} listingId={listing.id} />
    </div>
  )
}

function ReportModal({ open, onClose, listingId }: { open: boolean; onClose: () => void; listingId: number }) {
  const [reason, setReason] = useState<ReportReason>('misleading')
  const [details, setDetails] = useState('')
  const [error, setError] = useState<string | null>(null)
  const submit = useSubmitReport()
  const toast = useToast()

  const handleClose = () => {
    setDetails('')
    setError(null)
    onClose()
  }

  return (
    <Modal open={open} onClose={handleClose} title="Report this listing">
      <div className="flex flex-col gap-3">
        <label className="flex flex-col gap-1.5">
          <span className="text-sm font-medium text-ink-900">Reason</span>
          <select
            value={reason}
            onChange={(e) => setReason(e.target.value as ReportReason)}
            className="h-10 rounded-lg border border-stone-200 px-3 text-sm focus:outline-none focus:ring-2 focus:ring-trust-700"
          >
            <option value="fraud">Fraud / scam</option>
            <option value="duplicate">Duplicate listing</option>
            <option value="sold_already">Already sold or rented</option>
            <option value="misleading">Misleading information</option>
            <option value="inappropriate">Inappropriate content</option>
            <option value="other">Other</option>
          </select>
        </label>
        <textarea
          rows={3}
          value={details}
          onChange={(e) => setDetails(e.target.value)}
          placeholder="Any details that would help our team (optional)"
          className="rounded-lg border border-stone-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-trust-700"
        />
        {error && <p className="text-sm text-danger-600">{error}</p>}
        <Button
          isLoading={submit.isPending}
          onClick={() =>
            submit.mutate(
              { listingId, reason, details: details || undefined },
              {
                onSuccess: () => {
                  toast.success('Thanks — our team will review this listing.')
                  handleClose()
                },
                onError: (e) => setError(getErrorMessage(e)),
              },
            )
          }
        >
          Submit report
        </Button>
      </div>
    </Modal>
  )
}

function MessageModal({ open, onClose, listingId }: { open: boolean; onClose: () => void; listingId: number }) {
  const [message, setMessage] = useState('')
  const [error, setError] = useState<string | null>(null)
  const start = useStartConversation()
  const navigate = useNavigate()
  const toast = useToast()

  return (
    <Modal open={open} onClose={onClose} title="Message the owner">
      <div className="flex flex-col gap-3">
        <textarea
          rows={4}
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          placeholder="Hi, is this property still available?"
          className="rounded-lg border border-stone-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-trust-700"
        />
        {error && <p className="text-sm text-danger-600">{error}</p>}
        <Button
          isLoading={start.isPending}
          disabled={!message.trim()}
          onClick={() =>
            start.mutate(
              { listingId, message: message.trim() },
              {
                onSuccess: (conversation) => {
                  toast.success('Message sent.')
                  onClose()
                  navigate(`/messages/${conversation.id}`)
                },
                onError: (e) => setError(getErrorMessage(e)),
              },
            )
          }
        >
          Send message
        </Button>
      </div>
    </Modal>
  )
}

function ViewingModal({ open, onClose, listingId }: { open: boolean; onClose: () => void; listingId: number }) {
  const [datetime, setDatetime] = useState('')
  const [notes, setNotes] = useState('')
  const [error, setError] = useState<string | null>(null)
  const request = useRequestViewing()
  const toast = useToast()

  const handleClose = () => {
    setDatetime('')
    setNotes('')
    setError(null)
    onClose()
  }

  return (
    <Modal open={open} onClose={handleClose} title="Request a viewing">
      <div className="flex flex-col gap-3">
        <label className="flex flex-col gap-1.5">
          <span className="text-sm font-medium text-ink-900">Preferred date & time</span>
          <input
            type="datetime-local"
            value={datetime}
            min={new Date(Date.now() + 60 * 60 * 1000).toISOString().slice(0, 16)}
            onChange={(e) => setDatetime(e.target.value)}
            className="h-10 rounded-lg border border-stone-200 px-3 text-sm focus:outline-none focus:ring-2 focus:ring-trust-700"
          />
        </label>
        <textarea
          rows={3}
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          placeholder="Anything the owner should know (optional)"
          className="rounded-lg border border-stone-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-trust-700"
        />
        {error && <p className="text-sm text-danger-600">{error}</p>}
        <Button
          isLoading={request.isPending}
          disabled={!datetime}
          onClick={() =>
            request.mutate(
              { listingId, proposedDatetime: new Date(datetime).toISOString(), notes: notes || undefined },
              {
                onSuccess: () => {
                  toast.success('Viewing request sent to the owner.')
                  handleClose()
                },
                onError: (e) => setError(getErrorMessage(e)),
              },
            )
          }
        >
          Send request
        </Button>
      </div>
    </Modal>
  )
}

function RatingsSection({
  listingId,
  myRating,
  requireAuth,
}: {
  listingId: number
  myRating: { id: number; score: number; comment: string | null } | null
  requireAuth: (action: () => void) => void
}) {
  const { data, isPending } = useListingRatings(listingId)
  const submit = useSubmitRating()
  const remove = useDeleteRating()
  const toast = useToast()
  const [formOpen, setFormOpen] = useState(false)
  const [score, setScore] = useState(myRating?.score ?? 0)
  const [comment, setComment] = useState(myRating?.comment ?? '')
  const [error, setError] = useState<string | null>(null)

  const handleClose = () => {
    setFormOpen(false)
    setError(null)
  }

  const handleSubmit = () => {
    if (!score) return
    setError(null)
    submit.mutate(
      { listingId, score, comment: comment.trim() || undefined },
      {
        onSuccess: () => {
          toast.success(myRating ? 'Rating updated.' : 'Thanks for rating this listing.')
          handleClose()
        },
        onError: (e) => setError(getErrorMessage(e)),
      },
    )
  }

  return (
    <div>
      <div className="mb-2 flex items-center justify-between">
        <h2 className="font-display text-lg font-semibold text-ink-900">Ratings & reviews</h2>
        <Button
          size="sm"
          variant="outline"
          onClick={() => requireAuth(() => setFormOpen(true))}
        >
          <Star className="h-4 w-4" /> {myRating ? 'Edit your rating' : 'Rate this listing'}
        </Button>
      </div>

      <Modal open={formOpen} onClose={handleClose} title={myRating ? 'Edit your rating' : 'Rate this listing'}>
        <div className="flex flex-col gap-3">
          <div className="flex items-center gap-1">
            {[1, 2, 3, 4, 5].map((n) => (
              <button key={n} type="button" onClick={() => setScore(n)} aria-label={`${n} star${n === 1 ? '' : 's'}`}>
                <Star className={clsx('h-6 w-6', n <= score ? 'fill-warning-600 text-warning-600' : 'text-stone-300')} />
              </button>
            ))}
          </div>
          <textarea
            rows={3}
            value={comment}
            onChange={(e) => setComment(e.target.value)}
            maxLength={500}
            placeholder="Optional — share details about your experience"
            className="rounded-lg border border-stone-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-trust-700"
          />
          {error && <p className="text-sm text-danger-600">{error}</p>}
          <div className="flex gap-2">
            <Button size="sm" isLoading={submit.isPending} disabled={!score} onClick={handleSubmit}>
              {myRating ? 'Update rating' : 'Submit rating'}
            </Button>
            {myRating && (
              <Button
                size="sm"
                variant="ghost"
                isLoading={remove.isPending}
                onClick={() =>
                  remove.mutate(listingId, {
                    onSuccess: () => {
                      toast.success('Rating removed.')
                      setScore(0)
                      setComment('')
                      handleClose()
                    },
                  })
                }
              >
                <Trash2 className="h-4 w-4" /> Remove
              </Button>
            )}
            <Button size="sm" variant="ghost" onClick={handleClose}>
              Cancel
            </Button>
          </div>
        </div>
      </Modal>

      {isPending && <Skeleton className="h-20 w-full" />}
      {!isPending && data?.data.length === 0 && (
        <p className="text-sm text-ink-700/60">No reviews yet — be the first to share your experience.</p>
      )}
      {!isPending && data && data.data.length > 0 && (
        <ul className="flex flex-col gap-3">
          {data.data.map((r) => (
            <li key={r.id} className="rounded-card border border-stone-100 p-3">
              <div className="flex items-center justify-between gap-2">
                <div className="flex items-center gap-2">
                  <span className="flex items-center">
                    {[1, 2, 3, 4, 5].map((n) => (
                      <Star key={n} className={clsx('h-3.5 w-3.5', n <= r.score ? 'fill-warning-600 text-warning-600' : 'text-stone-300')} />
                    ))}
                  </span>
                  <span className="text-sm font-medium text-ink-900">{r.user?.name ?? 'A user'}</span>
                </div>
                <span className="text-xs text-ink-700/50">{new Date(r.created_at).toLocaleDateString()}</span>
              </div>
              {r.comment && <p className="mt-1 text-sm text-ink-700/80">{r.comment}</p>}
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}

function Fact({ icon, label, value }: { icon: React.ReactNode; label: string; value: string | number }) {
  return (
    <div className="flex flex-col items-center gap-1 text-center">
      <span className="text-ink-700/50">{icon}</span>
      <span className="text-sm font-semibold text-ink-900">{value}</span>
      <span className="text-xs text-ink-700/60">{label}</span>
    </div>
  )
}

function PriceHistoryLine({ history }: { history: { price: number; changed_at: string }[] }) {
  const sorted = [...history].sort((a, b) => new Date(a.changed_at).getTime() - new Date(b.changed_at).getTime())
  const first = sorted[0]
  const latest = sorted[sorted.length - 1]
  const changed = latest.price - first.price

  return (
    <details className="mt-2 text-xs text-ink-700/70">
      <summary className="cursor-pointer font-medium text-ink-900">
        Price history{' '}
        {changed !== 0 && (
          <span className={changed < 0 ? 'text-success-600' : 'text-danger-600'}>
            ({changed < 0 ? '↓' : '↑'} {formatNpr(Math.abs(changed))} since first listed)
          </span>
        )}
      </summary>
      <ul className="mt-2 flex flex-col gap-1 border-l border-stone-200 pl-3">
        {sorted.map((h, i) => (
          <li key={i}>
            {formatNpr(h.price)} — {new Date(h.changed_at).toLocaleDateString(undefined, { dateStyle: 'medium' })}
          </li>
        ))}
      </ul>
    </details>
  )
}

function IconButton({ label, onClick, children }: { label: string; onClick: () => void; children: React.ReactNode }) {
  return (
    <Button variant="ghost" size="sm" aria-label={label} onClick={onClick}>
      {children}
    </Button>
  )
}

function AdminTrustOverridePanel({ listingId, trust }: { listingId: number; trust: TrustScore | null }) {
  const [open, setOpen] = useState(false)
  const [score, setScore] = useState('')
  const [note, setNote] = useState('')
  const setOverride = useSetTrustOverride()
  const clearOverride = useClearTrustOverride()

  return (
    <div className="mt-2 rounded-lg border border-dashed border-accent-600/40 bg-accent-100/30 p-3">
      <p className="text-xs font-medium text-accent-600">Admin: trust score override</p>
      {!open ? (
        <div className="mt-1 flex gap-2">
          <Button size="sm" variant="outline" onClick={() => setOpen(true)}>
            {trust?.is_overridden ? 'Change override' : 'Override score'}
          </Button>
          {trust?.is_overridden && (
            <Button size="sm" variant="ghost" isLoading={clearOverride.isPending} onClick={() => clearOverride.mutate(listingId)}>
              Clear override
            </Button>
          )}
        </div>
      ) : (
        <div className="mt-2 flex flex-col gap-2">
          <input
            type="number"
            min="0"
            max="100"
            value={score}
            onChange={(e) => setScore(e.target.value)}
            placeholder="Score (0-100)"
            className="h-9 rounded-lg border border-stone-200 px-3 text-sm focus:outline-none focus:ring-2 focus:ring-trust-700"
          />
          <textarea
            rows={2}
            value={note}
            onChange={(e) => setNote(e.target.value)}
            placeholder="Reason for override (required, kept as an audit note)"
            className="rounded-lg border border-stone-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-trust-700"
          />
          <div className="flex gap-2">
            <Button
              size="sm"
              isLoading={setOverride.isPending}
              disabled={!score || !note.trim()}
              onClick={() =>
                setOverride.mutate(
                  { listingId, override_score: Number(score), note: note.trim() },
                  { onSuccess: () => setOpen(false) },
                )
              }
            >
              Save override
            </Button>
            <Button size="sm" variant="ghost" onClick={() => setOpen(false)}>Cancel</Button>
          </div>
        </div>
      )}
    </div>
  )
}

function AdminLandVerificationPanel({ propertyId, current }: { propertyId: number; current: LandProfile['document_verification_status'] }) {
  const verify = useVerifyLandProfile()

  return (
    <div className="rounded-lg border border-dashed border-accent-600/40 bg-accent-100/30 p-3">
      <p className="mb-2 text-xs font-medium text-accent-600">Admin: land document review</p>
      <div className="flex flex-wrap gap-2">
        {(['unverified', 'partial', 'verified'] as const).map((status) => (
          <Button
            key={status}
            size="sm"
            variant={current === status ? 'primary' : 'outline'}
            isLoading={verify.isPending && verify.variables?.status === status}
            onClick={() => verify.mutate({ propertyId, status })}
          >
            {status === 'unverified' ? 'Not reviewed' : status === 'partial' ? 'Partially reviewed' : 'Fully verified'}
          </Button>
        ))}
      </div>
    </div>
  )
}
