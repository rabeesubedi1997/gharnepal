import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'
import type { ListingDetail } from './listings'
import type { Banner } from './banners'

interface PaginatedResponse<T> {
  data: T[]
  meta: { current_page: number; last_page: number; total: number }
}

export function usePendingListings(status: string = 'pending_review') {
  return useQuery({
    queryKey: ['admin', 'listings', status],
    queryFn: async () => {
      const { data } = await apiClient.get<PaginatedResponse<ListingDetail>>('/admin/listings', { params: { status } })
      return data
    },
  })
}

export function useApproveListing() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (listingId: number) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.patch<{ data: ListingDetail }>(`/admin/listings/${listingId}/approve`)
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'listings'] }),
  })
}

export function useRejectListing() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ listingId, reason }: { listingId: number; reason: string }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.patch<{ data: ListingDetail }>(`/admin/listings/${listingId}/reject`, { reason })
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'listings'] }),
  })
}

// --- Dashboard stats ---

export interface DashboardStats {
  listings: { total: number; published: number; pending_review: number; featured_active: number }
  users: { total: number; owners: number; agents: number; suspended: number }
  agencies: { total: number; verified: number; pending: number }
  moderation_queue: { reports: number; duplicate_flags: number; verifications: number; community_notes: number }
  payments: { completed_count: number; completed_amount: number; pending: number }
}

export function useDashboardStats() {
  return useQuery({
    queryKey: ['admin', 'dashboard', 'stats'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: DashboardStats }>('/admin/dashboard/stats')
      return data.data
    },
    staleTime: 60 * 1000,
  })
}

// --- User management ---

export type AdminRoleKey = 'buyer' | 'owner' | 'agent' | 'agency_admin' | 'admin'
export type AccountStatus = 'active' | 'suspended' | 'pending'

export interface AdminUser {
  id: number
  name: string
  email: string
  phone: string | null
  status: AccountStatus
  email_verified: boolean
  phone_verified: boolean
  roles: AdminRoleKey[]
  agencies: string[]
  created_at: string
}

export interface UserFilters {
  q?: string
  role?: AdminRoleKey
  status?: AccountStatus
  page?: number
}

export function useAdminUsers(filters: UserFilters) {
  return useQuery({
    queryKey: ['admin', 'users', filters],
    queryFn: async () => {
      const { data } = await apiClient.get<PaginatedResponse<AdminUser>>('/admin/users', { params: filters })
      return data
    },
    placeholderData: (prev) => prev,
  })
}

export function useUpdateUserStatus() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ userId, status }: { userId: number; status: 'active' | 'suspended' }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.patch<{ data: AdminUser }>(`/admin/users/${userId}/status`, { status })
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'users'] }),
  })
}

export function useUpdateUserRoles() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ userId, roles }: { userId: number; roles: AdminRoleKey[] }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.put<{ data: AdminUser }>(`/admin/users/${userId}/roles`, { roles })
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'users'] }),
  })
}

// --- Agency management ---

export interface AdminAgency {
  id: number
  name: string
  slug: string
  logo_url: string | null
  description: string | null
  registration_number: string | null
  status: 'active' | 'suspended' | 'pending'
  is_verified: boolean
  verified_at: string | null
  member_count: number
  created_at: string
}

export function useAdminAgencies(status?: 'active' | 'suspended' | 'pending') {
  return useQuery({
    queryKey: ['admin', 'agencies', status],
    queryFn: async () => {
      const { data } = await apiClient.get<PaginatedResponse<AdminAgency>>('/admin/agencies', { params: status ? { status } : undefined })
      return data
    },
  })
}

export function useVerifyAgency() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (agencyId: number) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.patch<{ data: AdminAgency }>(`/admin/agencies/${agencyId}/verify`)
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'agencies'] }),
  })
}

export function useSuspendAgency() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (agencyId: number) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.patch<{ data: AdminAgency }>(`/admin/agencies/${agencyId}/suspend`)
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'agencies'] }),
  })
}

// --- Amenity management ---

export interface AdminAmenity {
  id: number
  key: string
  name: string
  name_ne: string | null
  category: string | null
  icon: string | null
}

export function useAdminAmenities() {
  return useQuery({
    queryKey: ['admin', 'amenities'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: AdminAmenity[] }>('/admin/amenities')
      return data.data
    },
  })
}

export function useCreateAmenity() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (input: { key: string; name: string; name_ne?: string; category?: string; icon?: string }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: AdminAmenity }>('/admin/amenities', input)
      return data.data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'amenities'] })
      queryClient.invalidateQueries({ queryKey: ['amenities'] })
    },
  })
}

export function useUpdateAmenity() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, ...input }: { id: number; key?: string; name?: string; name_ne?: string; category?: string; icon?: string }) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.put<{ data: AdminAmenity }>(`/admin/amenities/${id}`, input)
      return data.data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'amenities'] })
      queryClient.invalidateQueries({ queryKey: ['amenities'] })
    },
  })
}

export function useDeleteAmenity() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (id: number) => {
      await ensureCsrfCookie()
      await apiClient.delete(`/admin/amenities/${id}`)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'amenities'] })
      queryClient.invalidateQueries({ queryKey: ['amenities'] })
    },
  })
}

// --- Payment refunds ---

export function useRefundPayment() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (transactionId: number) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.patch(`/admin/payments/${transactionId}/refund`)
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'payments'] }),
  })
}

// --- Rating moderation ---

export interface AdminRating {
  id: number
  score: number
  comment: string | null
  status: 'visible' | 'hidden'
  user: { id: number; name: string } | null
  listing: { id: number; slug: string; title: string } | null
  created_at: string
}

export function useAdminRatings(status?: 'visible' | 'hidden') {
  return useQuery({
    queryKey: ['admin', 'ratings', status],
    queryFn: async () => {
      const { data } = await apiClient.get<PaginatedResponse<AdminRating>>('/admin/ratings', { params: status ? { status } : undefined })
      return data
    },
  })
}

export function useHideRating() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (id: number) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.patch<{ data: AdminRating }>(`/admin/ratings/${id}/hide`)
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'ratings'] }),
  })
}

export function useUnhideRating() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (id: number) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.patch<{ data: AdminRating }>(`/admin/ratings/${id}/unhide`)
      return data.data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['admin', 'ratings'] }),
  })
}

// --- Banner management ---

export interface BannerInput {
  title?: string
  subtitle?: string
  link_url?: string
  cta_label?: string
  sort_order?: number
  is_active?: boolean
  image?: File
}

function bannerFormData(input: BannerInput): FormData {
  const form = new FormData()
  if (input.title !== undefined) form.append('title', input.title)
  if (input.subtitle !== undefined) form.append('subtitle', input.subtitle)
  if (input.link_url !== undefined) form.append('link_url', input.link_url)
  if (input.cta_label !== undefined) form.append('cta_label', input.cta_label)
  if (input.sort_order !== undefined) form.append('sort_order', String(input.sort_order))
  if (input.is_active !== undefined) form.append('is_active', input.is_active ? '1' : '0')
  if (input.image) form.append('image', input.image)
  return form
}

export function useAdminBanners() {
  return useQuery({
    queryKey: ['admin', 'banners'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: Banner[] }>('/admin/banners')
      return data.data
    },
  })
}

export function useCreateBanner() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (input: BannerInput) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: Banner }>('/admin/banners', bannerFormData(input), {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      return data.data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'banners'] })
      queryClient.invalidateQueries({ queryKey: ['banners'] })
    },
  })
}

export function useUpdateBanner() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, ...input }: BannerInput & { id: number }) => {
      await ensureCsrfCookie()
      const form = bannerFormData(input)
      form.append('_method', 'PUT') // PHP won't parse a multipart PUT body — spoof via POST
      const { data } = await apiClient.post<{ data: Banner }>(`/admin/banners/${id}`, form, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      return data.data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'banners'] })
      queryClient.invalidateQueries({ queryKey: ['banners'] })
    },
  })
}

export function useDeleteBanner() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (id: number) => {
      await ensureCsrfCookie()
      await apiClient.delete(`/admin/banners/${id}`)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'banners'] })
      queryClient.invalidateQueries({ queryKey: ['banners'] })
    },
  })
}

// --- Conversation moderation (read-only — admins investigate reported abuse/spam, never post) ---

export interface AdminConversationParticipant {
  id: number
  name: string
  email: string
}

export interface AdminConversationMessage {
  id: number
  body: string
  sender: { id: number; name: string } | null
  read_at: string | null
  created_at: string
}

export interface AdminConversation {
  id: number
  status: 'open' | 'closed'
  listing: { id: number; slug: string; title: string } | null
  property_request: { id: number; purpose: string; property_type: string } | null
  buyer: AdminConversationParticipant | null
  owner: AdminConversationParticipant | null
  messages_count: number | null
  last_message_at: string | null
  last_message_preview: string | null
  messages?: AdminConversationMessage[]
}

export function useAdminConversations(filters: { status?: 'open' | 'closed'; q?: string }) {
  return useQuery({
    queryKey: ['admin', 'conversations', filters],
    queryFn: async () => {
      const { data } = await apiClient.get<PaginatedResponse<AdminConversation>>('/admin/conversations', { params: filters })
      return data
    },
    placeholderData: (prev) => prev,
  })
}

export function useAdminConversation(id: number | null) {
  return useQuery({
    queryKey: ['admin', 'conversations', 'detail', id],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: AdminConversation }>(`/admin/conversations/${id}`)
      return data.data
    },
    enabled: id != null,
  })
}
