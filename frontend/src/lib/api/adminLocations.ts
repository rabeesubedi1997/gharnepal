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
const municipalityCrud = makeCrud('municipalities')
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

export const useCreateMunicipality = () => useCreate(['admin', 'municipalities', 'create'], municipalityCrud.create)
export const useDeleteMunicipality = () => useDelete(['admin', 'municipalities', 'delete'], municipalityCrud.destroy)

export const useCreateWard = () => useCreate(['admin', 'wards', 'create'], wardCrud.create)
export const useDeleteWard = () => useDelete(['admin', 'wards', 'delete'], wardCrud.destroy)

export const useCreateNeighborhood = () => useCreate(['admin', 'neighborhoods', 'create'], neighborhoodCrud.create)
export const useDeleteNeighborhood = () => useDelete(['admin', 'neighborhoods', 'delete'], neighborhoodCrud.destroy)
