import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'

export interface EffectiveSeo {
  page_key: string
  page_type: 'static' | 'listing' | 'neighborhood' | 'agency'
  label: string
  title: string
  description: string | null
  keywords: string | null
  canonical_url: string
  og_image: string | null
  robots: { index: boolean; follow: boolean }
  structured_data: Record<string, unknown> | null
  has_override: boolean
  override_status: 'draft' | 'published' | null
}

/** Effective SEO for one of the site's static/category pages — home, buy, rent, etc. */
export function useStaticPageSeo(key: string | null) {
  return useQuery({
    queryKey: ['seo', 'page', key],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: EffectiveSeo }>(`/seo/pages/${key}`)
      return data.data
    },
    enabled: !!key,
    staleTime: 5 * 60 * 1000,
  })
}

export interface AdminSeoPageRow {
  page_key: string
  page_type: 'static' | 'listing' | 'neighborhood' | 'agency'
  label: string
  path: string
  has_override: boolean
  status: 'draft' | 'published' | null
  updated_at: string | null
}

export function useAdminSeoPages(filters: { type?: string; q?: string } = {}) {
  return useQuery({
    queryKey: ['admin', 'seo', 'pages', filters],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: AdminSeoPageRow[] }>('/admin/seo/pages', { params: filters })
      return data.data
    },
  })
}

export interface SeoOverride {
  meta_title: string | null
  meta_description: string | null
  meta_keywords: string | null
  og_image_url: string | null
  canonical_path: string | null
  robots_index: boolean
  robots_follow: boolean
  status: 'draft' | 'published'
  updated_at: string
}

export interface CompetitorScan {
  id: number
  page_key: string
  competitor_url: string
  scanned_title: string | null
  scanned_meta_description: string | null
  scanned_meta_keywords: string | null
  scanned_headings: string[]
  scanned_keywords: { word: string; count: number }[]
  scanned_og_image: string | null
  word_count: number | null
  scanned_by: string | null
  created_at: string
}

export interface AdminSeoPageDetail {
  effective: EffectiveSeo
  override: SeoOverride | null
  scans: CompetitorScan[]
}

/** `key` may contain a colon (e.g. "listing:some-slug") — encode it once here so callers just pass the raw key. */
function pageUrl(key: string) {
  return `/admin/seo/pages/${encodeURIComponent(key)}`
}

export function useAdminSeoPage(key: string) {
  return useQuery({
    queryKey: ['admin', 'seo', 'page', key],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: AdminSeoPageDetail }>(pageUrl(key))
      return data.data
    },
    enabled: !!key,
  })
}

export interface SeoPageInput {
  meta_title: string | null
  meta_description: string | null
  meta_keywords: string | null
  og_image_url: string | null
  canonical_path: string | null
  robots_index: boolean
  robots_follow: boolean
  status: 'draft' | 'published'
}

export function useSaveSeoPage(key: string) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (input: SeoPageInput) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.put<{ data: Omit<AdminSeoPageDetail, 'scans'> }>(pageUrl(key), input)
      return data.data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'seo'] })
      queryClient.invalidateQueries({ queryKey: ['seo'] })
    },
  })
}

export function useResetSeoPage(key: string) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async () => {
      await ensureCsrfCookie()
      await apiClient.delete(pageUrl(key))
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'seo'] })
      queryClient.invalidateQueries({ queryKey: ['seo'] })
    },
  })
}

export function useScanCompetitor(key: string) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (url: string) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: CompetitorScan }>(`${pageUrl(key)}/scan`, { url })
      return data.data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'seo', 'page', key] })
    },
  })
}

export function useDiscardScan(key: string) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (scanId: number) => {
      await ensureCsrfCookie()
      await apiClient.delete(`/admin/seo/scans/${scanId}`)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'seo', 'page', key] })
    },
  })
}
