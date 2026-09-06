import { useState } from 'react'
import { Calculator } from 'lucide-react'
import { useCalculateRental, type RentalCalculatorResult } from '../../lib/api/calculators'
import { useCurrentUser } from '../../lib/api/auth'
import { getErrorMessage } from '../../lib/api/errors'
import { formatNpr } from '../../design-system/tokens'
import { Card } from '../../components/ui/Card'
import { Input } from '../../components/ui/Input'
import { Button } from '../../components/ui/Button'
import { ErrorState } from '../../components/ui/ErrorState'

interface FormState {
  monthly_rent: string
  deposit_months: string
  utilities_monthly: string
  internet_monthly: string
  parking_monthly: string
  maintenance_monthly: string
  brokerage_fee: string
  moving_cost_estimate: string
}

const initial: FormState = {
  monthly_rent: '',
  deposit_months: '2',
  utilities_monthly: '',
  internet_monthly: '',
  parking_monthly: '',
  maintenance_monthly: '',
  brokerage_fee: '',
  moving_cost_estimate: '',
}

export function RentalCalculator() {
  const [form, setForm] = useState<FormState>(initial)
  const [result, setResult] = useState<RentalCalculatorResult | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [saveName, setSaveName] = useState('')
  const [saved, setSaved] = useState(false)
  const calculate = useCalculateRental()
  const { data: user } = useCurrentUser()

  const set = (key: keyof FormState) => (e: React.ChangeEvent<HTMLInputElement>) => setForm({ ...form, [key]: e.target.value })

  const handleCalculate = () => {
    setError(null)
    setSaved(false)
    calculate.mutate(
      {
        monthly_rent: Number(form.monthly_rent) || 0,
        deposit_months: form.deposit_months ? Number(form.deposit_months) : undefined,
        utilities_monthly: form.utilities_monthly ? Number(form.utilities_monthly) : undefined,
        internet_monthly: form.internet_monthly ? Number(form.internet_monthly) : undefined,
        parking_monthly: form.parking_monthly ? Number(form.parking_monthly) : undefined,
        maintenance_monthly: form.maintenance_monthly ? Number(form.maintenance_monthly) : undefined,
        brokerage_fee: form.brokerage_fee ? Number(form.brokerage_fee) : undefined,
        moving_cost_estimate: form.moving_cost_estimate ? Number(form.moving_cost_estimate) : undefined,
      },
      { onSuccess: (data) => setResult(data.result), onError: (e) => setError(getErrorMessage(e)) },
    )
  }

  const handleSave = () => {
    calculate.mutate(
      {
        monthly_rent: Number(form.monthly_rent) || 0,
        deposit_months: form.deposit_months ? Number(form.deposit_months) : undefined,
        utilities_monthly: form.utilities_monthly ? Number(form.utilities_monthly) : undefined,
        internet_monthly: form.internet_monthly ? Number(form.internet_monthly) : undefined,
        parking_monthly: form.parking_monthly ? Number(form.parking_monthly) : undefined,
        maintenance_monthly: form.maintenance_monthly ? Number(form.maintenance_monthly) : undefined,
        brokerage_fee: form.brokerage_fee ? Number(form.brokerage_fee) : undefined,
        moving_cost_estimate: form.moving_cost_estimate ? Number(form.moving_cost_estimate) : undefined,
        save: true,
        name: saveName || undefined,
      },
      { onSuccess: () => setSaved(true), onError: (e) => setError(getErrorMessage(e)) },
    )
  }

  return (
    <div className="mx-auto max-w-4xl">
      <div className="mb-6 flex items-center gap-2">
        <Calculator className="h-6 w-6 text-trust-700" />
        <h1 className="font-display text-2xl font-semibold text-ink-900">True monthly rental cost</h1>
      </div>
      <p className="mb-6 text-sm text-ink-700/70">
        A quoted rent rarely tells the whole story. Add the extras to see what actually leaves
        your account each month, and what you'll need on move-in day.
      </p>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <Card className="flex flex-col gap-4 p-4">
          <Input label="Monthly rent (NPR)" type="number" min="0" value={form.monthly_rent} onChange={set('monthly_rent')} />
          <Input label="Deposit (months of rent)" type="number" min="0" step="0.5" value={form.deposit_months} onChange={set('deposit_months')} />
          <div className="grid grid-cols-2 gap-3">
            <Input label="Utilities / month" type="number" min="0" value={form.utilities_monthly} onChange={set('utilities_monthly')} />
            <Input label="Internet / month" type="number" min="0" value={form.internet_monthly} onChange={set('internet_monthly')} />
            <Input label="Parking / month" type="number" min="0" value={form.parking_monthly} onChange={set('parking_monthly')} />
            <Input label="Maintenance / month" type="number" min="0" value={form.maintenance_monthly} onChange={set('maintenance_monthly')} />
          </div>
          <Input label="Brokerage fee (one-time)" type="number" min="0" value={form.brokerage_fee} onChange={set('brokerage_fee')} />
          <Input label="Estimated moving cost (one-time)" type="number" min="0" value={form.moving_cost_estimate} onChange={set('moving_cost_estimate')} />
          <Button isLoading={calculate.isPending} disabled={!form.monthly_rent} onClick={handleCalculate}>
            Calculate
          </Button>
        </Card>

        <div className="flex flex-col gap-4">
          {error && <ErrorState description={error} />}
          {result && (
            <Card className="flex flex-col gap-4 p-4">
              <div>
                <p className="text-sm text-ink-700/60">Monthly recurring cost</p>
                <p className="text-2xl font-semibold text-trust-700">{formatNpr(result.monthly_recurring_total)}</p>
              </div>
              <div>
                <p className="text-sm text-ink-700/60">One-time move-in cost</p>
                <p className="text-xl font-semibold text-ink-900">{formatNpr(result.one_time_total)}</p>
              </div>
              <div className="rounded-lg bg-trust-100 p-3">
                <p className="text-sm text-trust-700">Total needed for first month</p>
                <p className="text-xl font-bold text-trust-700">{formatNpr(result.first_month_total)}</p>
              </div>
              <dl className="grid grid-cols-2 gap-2 text-sm">
                {Object.entries(result.breakdown).map(([key, value]) => (
                  <div key={key} className="flex justify-between border-b border-stone-100 py-1">
                    <dt className="text-ink-700/60">{key.replace(/_/g, ' ')}</dt>
                    <dd className="font-medium text-ink-900">{formatNpr(value)}</dd>
                  </div>
                ))}
              </dl>

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
