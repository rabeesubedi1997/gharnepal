import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'
import type { Property, PropertyType } from './properties'
import type { Amenity } from './amenities'
import type { TrustScore } from './trust'
import type { EffectiveSeo } from './seo'

export interface MediaItem {
  id: number
  type: 'image' | 'video' | 'floor_plan' | 'document'
  url: string
  sort_order: number
}

export type ListingPurpose = 'sale' | 'rent'
export type ListingStatus =
  | 'draft'
  | 'pending_review'
  | 'published'
  | 'paused'
  | 'rented'
  | 'sold'
  | 'rejected'
  | 'expired'

export interface ListingSummary {
  id: number
  slug: string
  reference_code: string
  title: string
  purpose: ListingPurpose
  price: number
  price_period: 'total' | 'monthly' | null
  currency: string
  negotiable: boolean
  status: ListingStatus
  property_type: PropertyType | null
  bedrooms: number | null
  bathrooms: number | null
  area_sqm: number | null
  cover_image_url: string | null
  location: {
    municipality: string | null
    ward_number: number | null
    neighborhood: string | null
    lat: number | null
    lng: number | null
  } | null
  published_at: string | null
  views_count: number
  trust_score: number | null
  is_featured: boolean
  rating: { average: number | null; count: number }
}

export interface ListingDetail {
  seo: EffectiveSeo
  id: number
  slug: string
  reference_code: string
  title: string
  description: string | null
  purpose: ListingPurpose
  price: number
  price_period: 'total' | 'monthly' | null
  currency: string
  negotiable: boolean
  availability_date: string | null
  status: ListingStatus
  published_at: string | null
  views_count: number
  is_featured: boolean
  featured_until: string | null
  property: Property
  amenities: Amenity[]
  poster: { name: string; member_since: string; agency: { name: string; slug: string } | null; whatsapp_url: string | null } | null
  trust: TrustScore | null
  price_history: { price: number; changed_at: string }[]
  similar_listings: ListingSummary[]
  rating: { average: number | null; count: number }
  my_rating: { id: number; score: number; comment: string | null } | null
}

export interface SearchFilters {
  purpose?: ListingPurpose
  property_type?: PropertyType
  min_price?: number
  max_price?: number
  bedrooms_min?: number
  province_id?: number
  district_id?: number
  municipality_id?: number
  ward_id?: number
  neighborhood_id?: number
  q?: string
  sort?: 'newest' | 'price_asc' | 'price_desc'
  lalpurja_available?: 'yes' | 'no' | 'in_process' | 'unknown'
  road_access?: boolean
  page?: number
}

interface PaginatedResponse<T> {
  data: T[]
  meta: { current_page: number; last_page: number; total: number }
}

async function searchListings(filters: SearchFilters): Promise<PaginatedResponse<ListingSummary>> {
  const { data } = await apiClient.get<PaginatedResponse<ListingSummary>>('/listings', { params: filters })
  return data
}

export function useListingSearch(filters: SearchFilters) {
  return useQuery({
    queryKey: ['listings', 'search', filters],
    queryFn: () => searchListings(filters),
    placeholderData: (prev) => prev,
  })
}

export function useListingDetail(slug: string | undefined) {
  return useQuery({
    queryKey: ['listings', 'detail', slug],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: ListingDetail }>(`/listings/${slug}`)
      return data.data
    },
    enabled: !!slug,
  })
}

export interface CreateListingInput {
  purpose: ListingPurpose
  price: number
  price_period?: 'total' | 'monthly'
  negotiable?: boolean
  availability_date?: string
  title: string
  description?: string
  amenity_ids?: number[]
}

export function useCreateListing() {
  return useMutation({
    mutationFn: async ({ propertyId, input }: { propertyId: number; input: CreateListingInput }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: ListingDetail }>(`/properties/${propertyId}/listings`, input)
      return data.data
    },
  })
}

export function useTransitionListing() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ listingId, action }: { listingId: number; action: string }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.patch<{ data: ListingDetail }>(`/owner/listings/${listingId}/transition`, { action })
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['owner'] }),
  })
}

/** A listing's own editable content — title/price/description/etc, not the
 * property/address it belongs to (that's fixed at creation). */
export function useOwnerListing(listingId: number | undefined) {
  return useQuery({
    queryKey: ['owner', 'listing', listingId],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: ListingDetail }>(`/owner/listings/${listingId}`)
      return data.data
    },
    enabled: !!listingId,
  })
}

export interface UpdateListingInput {
  title?: string
  description?: string
  price?: number
  price_period?: 'total' | 'monthly'
  negotiable?: boolean
  availability_date?: string
  amenity_ids?: number[]
}

export function useUpdateListing() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ listingId, input }: { listingId: number; input: UpdateListingInput }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.put<{ data: ListingDetail }>(`/owner/listings/${listingId}`, input)
      return data.data
    },
    onSuccess: (listing, { listingId }) => {
      queryClient.invalidateQueries({ queryKey: ['owner'] })
      queryClient.invalidateQueries({ queryKey: ['owner', 'listing', listingId] })
      queryClient.invalidateQueries({ queryKey: ['listings', 'detail', listing.slug] })
    },
  })
}

export interface OwnerProperty extends Property {
  id: number
  listings: {
    id: number
    slug: string
    title: string
    status: ListingStatus
    purpose: ListingPurpose
    price: number
    is_featured: boolean
    featured_until: string | null
  }[]
}

export function useOwnerProperties() {
  return useQuery({
    queryKey: ['owner', 'properties'],
    queryFn: async () => {
      const { data } = await apiClient.get<PaginatedResponse<OwnerProperty>>('/owner/properties')
      return data
    },
  })
}
