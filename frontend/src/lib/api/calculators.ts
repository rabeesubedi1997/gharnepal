import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiClient, ensureCsrfCookie } from './client'

export interface RentalCalculatorInput {
  monthly_rent: number
  deposit_months?: number
  utilities_monthly?: number
  internet_monthly?: number
  parking_monthly?: number
  maintenance_monthly?: number
  brokerage_fee?: number
  moving_cost_estimate?: number
  save?: boolean
  name?: string
  listing_id?: number
}

export interface RentalCalculatorResult {
  breakdown: {
    monthly_rent: number
    utilities_monthly: number
    internet_monthly: number
    parking_monthly: number
    maintenance_monthly: number
    deposit: number
    brokerage_fee: number
    moving_cost_estimate: number
  }
  monthly_recurring_total: number
  one_time_total: number
  first_month_total: number
}

export interface PurchaseCalculatorInput {
  property_price: number
  down_payment_percent?: number
  loan_interest_rate_annual?: number
  loan_tenure_years?: number
  registration_cost_percent?: number
  legal_fees?: number
  renovation_estimate?: number
  monthly_rent_estimate?: number
  save?: boolean
  name?: string
  listing_id?: number
}

export interface PurchaseCalculatorResult {
  breakdown: {
    property_price: number
    down_payment: number
    loan_amount: number
    registration_cost: number
    legal_fees: number
    renovation_estimate: number
  }
  monthly_repayment_estimate: number
  total_upfront_cost: number
  rental_yield_percent: number | null
  assumptions: {
    loan_interest_rate_annual: number
    loan_tenure_years: number
    registration_cost_percent: number
  }
}

export interface CalculatorScenario {
  id: number
  type: 'rental' | 'purchase'
  name: string | null
  inputs: Record<string, unknown>
  result: RentalCalculatorResult | PurchaseCalculatorResult
  listing_id: number | null
  created_at: string
}

export function useCalculateRental() {
  return useMutation({
    mutationFn: async (input: RentalCalculatorInput) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: { result: RentalCalculatorResult; scenario: CalculatorScenario | null } }>(
        '/calculators/rental',
        input,
      )
      return data.data
    },
  })
}

export function useCalculatePurchase() {
  return useMutation({
    mutationFn: async (input: PurchaseCalculatorInput) => {
      await ensureCsrfCookie()
      const { data } = await apiClient.post<{ data: { result: PurchaseCalculatorResult; scenario: CalculatorScenario | null } }>(
        '/calculators/purchase',
        input,
      )
      return data.data
    },
  })
}

export function useSavedScenarios() {
  return useQuery({
    queryKey: ['calculator-scenarios'],
    queryFn: async () => {
      const { data } = await apiClient.get<{ data: CalculatorScenario[] }>('/account/calculator-scenarios')
      return data.data
    },
  })
}

export function useDeleteScenario() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (id: number) => {
      await ensureCsrfCookie()
      await apiClient.delete(`/account/calculator-scenarios/${id}`)
    },
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['calculator-scenarios'] }),
  })
}
