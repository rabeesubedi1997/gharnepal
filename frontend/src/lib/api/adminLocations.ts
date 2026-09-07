import { useMutation, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'

interface Mutators {
  create: (payload: Record<string, unknown>) => Promise<unknown>
  destroy: (id: number) => Promise<void>
}

function makeCrud(resource: string): Mutators {
  return {
    create: async (payload) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post(`/admin/locations/${resource}`, payload)
      return data
    },
    destroy: async (id) => {
      await ensureCsrfCookie()
      await apiClient.delete(`/admin/locations/${resource}/${id}`)
    },
  }
}

const provinceCrud = makeCrud('provinces')
const districtCrud = makeCrud('districts')
const wardCrud = makeCrud('wards')
const neighborhoodCrud = makeCrud('neighborhoods')

function useCreate(mutationKey: string[], fn: (payload: Record<string, unknown>) => Promise<unknown>) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: fn,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['locations'] }),
    mutationKey,
  })
}

function useDelete(mutationKey: string[], fn: (id: number) => Promise<void>) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: fn,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['locations'] }),
    mutationKey,
  })
}

export const useCreateProvince = () => useCreate(['admin', 'provinces', 'create'], provinceCrud.create)
export const useDeleteProvince = () => useDelete(['admin', 'provinces', 'delete'], provinceCrud.destroy)

export const useCreateDistrict = () => useCreate(['admin', 'districts', 'create'], districtCrud.create)
export const useDeleteDistrict = () => useDelete(['admin', 'districts', 'delete'], districtCrud.destroy)

// Municipalities support an optional photo (shown on the homepage "Browse by
// city" tiles), so create/update always go through multipart form data
// rather than the plain-JSON generic CRUD used by the other location tiers.
export interface MunicipalityInput {
  district_id?: number
  name?: string
  name_ne?: string
  type?: string
  code?: string
  ward_count?: number
  image?: File
}

function municipalityFormData(input: MunicipalityInput): FormData {
  const form = new FormData()
  if (input.district_id !== undefined) form.append('district_id', String(input.district_id))
  if (input.name !== undefined) form.append('name', input.name)
  if (input.name_ne !== undefined) form.append('name_ne', input.name_ne)
  if (input.type !== undefined) form.append('type', input.type)
  if (input.code !== undefined) form.append('code', input.code)
  if (input.ward_count !== undefined) form.append('ward_count', String(input.ward_count))
  if (input.image) form.append('image', input.image)
  return form
}

export function useCreateMunicipality() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationKey: ['admin', 'municipalities', 'create'],
    mutationFn: async (input: MunicipalityInput) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post('/admin/locations/municipalities', municipalityFormData(input), {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      return data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['locations'] }),
  })
}

export function useUpdateMunicipality() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationKey: ['admin', 'municipalities', 'update'],
    mutationFn: async ({ id, ...input }: MunicipalityInput & { id: number }) => {
      await ensureCsrfCookie()
      const form = municipalityFormData(input)
      form.append('_method', 'PUT') // PHP won't parse a multipart PUT body — spoof via POST
      const { data } = await apiClient.post(`/admin/locations/municipalities/${id}`, form, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      return data
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['locations'] }),
  })
}

export const useDeleteMunicipality = () => useDelete(['admin', 'municipalities', 'delete'], makeCrud('municipalities').destroy)

export const useCreateWard = () => useCreate(['admin', 'wards', 'create'], wardCrud.create)
export const useDeleteWard = () => useDelete(['admin', 'wards', 'delete'], wardCrud.destroy)

export const useCreateNeighborhood = () => useCreate(['admin', 'neighborhoods', 'create'], neighborhoodCrud.create)
export const useDeleteNeighborhood = () => useDelete(['admin', 'neighborhoods', 'delete'], neighborhoodCrud.destroy)
