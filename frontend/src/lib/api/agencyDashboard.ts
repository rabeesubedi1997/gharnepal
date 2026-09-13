import { useQuery } from '@tanstack/react-query'
import { apiClient } from './client'

export interface AgencyOverview {
  agency: {
    name: string
    slug: string
    logo_url: string | null
    registration_number: string | null
    founded_year: number | null
    is_verified: boolean
    member_count: number
  }
  portfolio: {
    active_count: number
    new_this_week: number
    by_city: { city: string; count: number }[]
  }
  inquiries_30d: {
    count: number
    response_rate_pct: number | null
  }
  site_visits: {
    upcoming_7d: number
    today: number
  }
  for_sale_portfolio_value: {
    total: number
    listing_count: number
  }
  alert_reach: number
}

export interface AgencyListingRow {
  id: number
  slug: string
  reference_code: string
  title: string
  purpose: 'sale' | 'rent'
  price: number
  price_period: 'total' | 'monthly' | null
  currency: string
  property_type: string | null
  area_sqm: number | null
  cover_image_url: string | null
  location: { municipality: string | null; ward_number: number | null } | null
  published_at: string | null
  inquiries_count: number
  leads_count: number
}

export interface AgencyInquiry {
  id: number
  buyer_name: string | null
  listing_title: string | null
  listing_slug: string | null
  last_message_at: string | null
  message_count: number
}

export interface AgencySiteVisit {
  id: number
  when: string | null
  is_confirmed: boolean
  listing_title: string | null
  listing_slug: string | null
  municipality: string | null
  requester_name: string | null
}

export function useAgencyOverview(enabled: boolean) {
  return useQuery({
    queryKey: ['agency-dashboard', 'overview'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: AgencyOverview }>('/agency/dashboard/overview')
      return data.data
    },
    enabled,
  })
}

export function useAgencyListings(params: { category?: string; search?: string; sort?: string; page?: number }, enabled: boolean) {
  return useQuery({
    queryKey: ['agency-dashboard', 'listings', params],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: AgencyListingRow[]; meta: { current_page: number; last_page: number; total: number } }>(
        '/agency/dashboard/listings',
        { params },
      )
      return data
    },
    enabled,
  })
}

export function useAgencyInquiries(enabled: boolean) {
  return useQuery({
    queryKey: ['agency-dashboard', 'inquiries'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: AgencyInquiry[] }>('/agency/dashboard/inquiries')
      return data.data
    },
    enabled,
  })
}

export function useAgencySiteVisits(enabled: boolean) {
  return useQuery({
    queryKey: ['agency-dashboard', 'site-visits'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: AgencySiteVisit[] }>('/agency/dashboard/site-visits')
      return data.data
    },
    enabled,
  })
}
