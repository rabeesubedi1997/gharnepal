import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'
import type { EffectiveSeo } from './seo'

export interface BlogPostSummary {
  id: number
  title: string
  slug: string
  excerpt: string | null
  cover_image_url: string | null
  author: string | null
  published_at: string | null
}

export interface BlogPost extends BlogPostSummary {
  seo: EffectiveSeo
  body: string
}

export interface AdminBlogPost {
  id: number
  title: string
  slug: string
  excerpt: string | null
  body: string
  cover_image_url: string | null
  status: 'draft' | 'published'
  author: string | null
  published_at: string | null
  updated_at: string
}

interface PaginatedResponse<T> {
  data: T[]
  meta: { current_page: number; last_page: number; total: number }
}

export function useBlogPosts(page = 1) {
  return useQuery({
    queryKey: ['blog', page],
    queryFn: async () => {
      const { data } = await apiClient.get<PaginatedResponse<BlogPostSummary>>('/blog', { params: { page } })
      return data
    },
  })
}

export function useBlogPost(slug: string | undefined) {
  return useQuery({
    queryKey: ['blog', 'detail', slug],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: BlogPost }>(`/blog/${slug}`)
      return data.data
    },
    enabled: !!slug,
  })
}

export function useAdminBlogPosts() {
  return useQuery({
    queryKey: ['admin', 'blog'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: AdminBlogPost[] }>('/admin/blog')
      return data.data
    },
  })
}

export function useAdminBlogPost(id: number | undefined) {
  return useQuery({
    queryKey: ['admin', 'blog', id],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: AdminBlogPost }>(`/admin/blog/${id}`)
      return data.data
    },
    enabled: !!id,
  })
}

export interface BlogPostInput {
  title?: string
  excerpt?: string
  body?: string
  status?: 'draft' | 'published'
  cover_image?: File
}

function blogFormData(input: BlogPostInput): FormData {
  const form = new FormData()
  if (input.title !== undefined) form.append('title', input.title)
  if (input.excerpt !== undefined) form.append('excerpt', input.excerpt)
  if (input.body !== undefined) form.append('body', input.body)
  if (input.status !== undefined) form.append('status', input.status)
  if (input.cover_image) form.append('cover_image', input.cover_image)
  return form
}

export function useCreateBlogPost() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (input: BlogPostInput) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: AdminBlogPost }>('/admin/blog', blogFormData(input), {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      return data.data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'blog'] })
      queryClient.invalidateQueries({ queryKey: ['blog'] })
    },
  })
}

export function useUpdateBlogPost() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, ...input }: BlogPostInput & { id: number }) => {
      await ensureCsrfCookie()
      const form = blogFormData(input)
      form.append('_method', 'PUT')
      const { data } = await apiClient.post<{ data: AdminBlogPost }>(`/admin/blog/${id}`, form, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      return data.data
    },
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'blog'] })
      queryClient.invalidateQueries({ queryKey: ['admin', 'blog', variables.id] })
      queryClient.invalidateQueries({ queryKey: ['blog'] })
    },
  })
}

export function useDeleteBlogPost() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (id: number) => {
      await ensureCsrfCookie()
      await apiClient.delete(`/admin/blog/${id}`)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'blog'] })
      queryClient.invalidateQueries({ queryKey: ['blog'] })
    },
  })
}
