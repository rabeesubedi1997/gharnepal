import { useState } from 'react'
import { Calculator } from 'lucide-react'
import { useCalculatePurchase, type PurchaseCalculatorResult } from '../../lib/api/calculators'
import { useCurrentUser } from '../../lib/api/auth'
import { getErrorMessage } from '../../lib/api/errors'
import { formatNpr } from '../../design-system/tokens'
import { Card } from '../../components/ui/Card'
import { Input } from '../../components/ui/Input'
import { Button } from '../../components/ui/Button'
import { ErrorState } from '../../components/ui/ErrorState'

interface FormState {
  property_price: string
  down_payment_percent: string
  loan_interest_rate_annual: string
  loan_tenure_years: string
  registration_cost_percent: string
  legal_fees: string
  renovation_estimate: string
  monthly_rent_estimate: string
}

const initial: FormState = {
  property_price: '',
  down_payment_percent: '20',
  loan_interest_rate_annual: '10',
  loan_tenure_years: '20',
  registration_cost_percent: '4',
  legal_fees: '',
  renovation_estimate: '',
  monthly_rent_estimate: '',
}

export function PurchaseCalculator() {
  const [form, setForm] = useState<FormState>(initial)
  const [result, setResult] = useState<PurchaseCalculatorResult | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [saveName, setSaveName] = useState('')
  const [saved, setSaved] = useState(false)
  const calculate = useCalculatePurchase()
  const { data: user } = useCurrentUser()

  const set = (key: keyof FormState) => (e: React.ChangeEvent<HTMLInputElement>) => setForm({ ...form, [key]: e.target.value })

  const buildInput = () => ({
    property_price: Number(form.property_price) || 0,
    down_payment_percent: form.down_payment_percent ? Number(form.down_payment_percent) : undefined,
    loan_interest_rate_annual: form.loan_interest_rate_annual ? Number(form.loan_interest_rate_annual) : undefined,
    loan_tenure_years: form.loan_tenure_years ? Number(form.loan_tenure_years) : undefined,
    registration_cost_percent: form.registration_cost_percent ? Number(form.registration_cost_percent) : undefined,
    legal_fees: form.legal_fees ? Number(form.legal_fees) : undefined,
    renovation_estimate: form.renovation_estimate ? Number(form.renovation_estimate) : undefined,
    monthly_rent_estimate: form.monthly_rent_estimate ? Number(form.monthly_rent_estimate) : undefined,
  })

  const handleCalculate = () => {
    setError(null)
    setSaved(false)
    calculate.mutate(buildInput(), { onSuccess: (data) => setResult(data.result), onError: (e) => setError(getErrorMessage(e)) })
  }

  const handleSave = () => {
    calculate.mutate(
      { ...buildInput(), save: true, name: saveName || undefined },
      { onSuccess: () => setSaved(true), onError: (e) => setError(getErrorMessage(e)) },
    )
  }

  return (
    <div className="mx-auto max-w-4xl">
      <div className="mb-6 flex items-center gap-2">
        <Calculator className="h-6 w-6 text-trust-700" />
        <h1 className="font-display text-2xl font-semibold text-ink-900">True purchase cost</h1>
      </div>
      <p className="mb-6 text-sm text-ink-700/70">
        Registration duty and legal fees vary by province and municipality — the defaults below
        are adjustable estimates, not an official quote.
      </p>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <Card className="flex flex-col gap-4 p-4">
          <Input label="Property price (NPR)" type="number" min="0" value={form.property_price} onChange={set('property_price')} />
          <div className="grid grid-cols-2 gap-3">
            <Input label="Down payment %" type="number" min="0" max="100" value={form.down_payment_percent} onChange={set('down_payment_percent')} />
            <Input label="Loan interest %/yr" type="number" min="0" step="0.1" value={form.loan_interest_rate_annual} onChange={set('loan_interest_rate_annual')} />
            <Input label="Loan tenure (years)" type="number" min="1" value={form.loan_tenure_years} onChange={set('loan_tenure_years')} />
            <Input label="Registration cost %" type="number" min="0" step="0.1" value={form.registration_cost_percent} onChange={set('registration_cost_percent')} />
          </div>
          <Input label="Legal fees (one-time)" type="number" min="0" value={form.legal_fees} onChange={set('legal_fees')} />
          <Input label="Renovation estimate (one-time)" type="number" min="0" value={form.renovation_estimate} onChange={set('renovation_estimate')} />
          <Input
            label="Expected monthly rent (optional — for rental yield)"
            type="number"
            min="0"
            value={form.monthly_rent_estimate}
            onChange={set('monthly_rent_estimate')}
          />
          <Button isLoading={calculate.isPending} disabled={!form.property_price} onClick={handleCalculate}>
            Calculate
          </Button>
        </Card>

        <div className="flex flex-col gap-4">
          {error && <ErrorState description={error} />}
          {result && (
            <Card className="flex flex-col gap-4 p-4">
              <div>
                <p className="text-sm text-ink-700/60">Estimated monthly repayment</p>
                <p className="text-2xl font-semibold text-trust-700">{formatNpr(result.monthly_repayment_estimate)}</p>
              </div>
              <div>
                <p className="text-sm text-ink-700/60">Total upfront cost</p>
                <p className="text-xl font-semibold text-ink-900">{formatNpr(result.total_upfront_cost)}</p>
              </div>
              {result.rental_yield_percent != null && (
                <div className="rounded-lg bg-trust-100 p-3">
                  <p className="text-sm text-trust-700">Estimated rental yield</p>
                  <p className="text-xl font-bold text-trust-700">{result.rental_yield_percent}% / year</p>
                </div>
              )}
              <dl className="grid grid-cols-2 gap-2 text-sm">
                {Object.entries(result.breakdown).map(([key, value]) => (
                  <div key={key} className="flex justify-between border-b border-stone-100 py-1">
                    <dt className="text-ink-700/60">{key.replace(/_/g, ' ')}</dt>
                    <dd className="font-medium text-ink-900">{formatNpr(value)}</dd>
                  </div>
                ))}
              </dl>
              <p className="text-xs text-ink-700/50">
                Assumes {result.assumptions.loan_interest_rate_annual}% annual interest over{' '}
                {result.assumptions.loan_tenure_years} years and {result.assumptions.registration_cost_percent}%
                registration cost — adjust these above to match your situation.
              </p>

              {user && !saved && (
                <div className="flex gap-2 border-t border-stone-100 pt-3">
                  <Input placeholder="Name this scenario (optional)" value={saveName} onChange={(e) => setSaveName(e.target.value)} className="flex-1" />
                  <Button variant="outline" size="sm" isLoading={calculate.isPending} onClick={handleSave}>Save</Button>
                </div>
              )}
              {saved && <p className="border-t border-stone-100 pt-3 text-sm text-success-600">Saved to your dashboard.</p>}
              {!user && (
                <p className="border-t border-stone-100 pt-3 text-xs text-ink-700/50">Log in to save this scenario for later.</p>
              )}
            </Card>
          )}
        </div>
      </div>
    </div>
  )
}
