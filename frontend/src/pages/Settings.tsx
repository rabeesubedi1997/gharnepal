import { useState } from 'react'
import { KeyRound, Phone, Settings as SettingsIcon, ShieldCheck, User } from 'lucide-react'
import {
  useCurrentUser,
  useRequestPhoneOtp,
  useUpdatePassword,
  useUpdateProfile,
  useVerifyPhoneOtp,
} from '../lib/api/auth'
import { getErrorMessage } from '../lib/api/errors'
import { Card } from '../components/ui/Card'
import { Badge } from '../components/ui/Badge'
import { Button } from '../components/ui/Button'
import { Input } from '../components/ui/Input'
import { Skeleton } from '../components/ui/Skeleton'

export function Settings() {
  const { data: user, isPending } = useCurrentUser()

  if (isPending || !user) {
    return (
      <div className="mx-auto flex max-w-2xl flex-col gap-4">
        <Skeleton className="h-8 w-48" />
        <Skeleton className="h-40 w-full" />
        <Skeleton className="h-40 w-full" />
      </div>
    )
  }

  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-6">
      <div>
        <h1 className="flex items-center gap-2 font-display text-2xl font-semibold text-ink-900">
          <SettingsIcon className="h-6 w-6 text-trust-700" /> Account settings
        </h1>
        <p className="mt-1 text-sm text-ink-700/70">Manage your profile, phone verification, and password.</p>
      </div>

      <ProfileSection name={user.name} email={user.email} />
      <PhoneSection phone={user.phone} verified={user.phone_verified} />
      <PasswordSection />
    </div>
  )
}

function ProfileSection({ name, email }: { name: string; email: string }) {
  const [value, setValue] = useState(name)
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const update = useUpdateProfile()

  return (
    <Card className="flex flex-col gap-3 p-4">
      <h2 className="flex items-center gap-2 font-display text-base font-semibold text-ink-900">
        <User className="h-4 w-4 text-trust-700" /> Profile
      </h2>
      <Input label="Name" value={value} onChange={(e) => { setValue(e.target.value); setSaved(false) }} />
      <Input label="Email" value={email} disabled hint="Contact support to change your email address." />
      {error && <p className="text-sm text-danger-600">{error}</p>}
      {saved && <p className="text-sm text-success-600">Saved.</p>}
      <Button
        className="self-start"
        size="sm"
        isLoading={update.isPending}
        disabled={!value.trim() || value.trim() === name}
        onClick={() => {
          setError(null)
          update.mutate(value.trim(), {
            onSuccess: () => setSaved(true),
            onError: (e) => setError(getErrorMessage(e)),
          })
        }}
      >
        Save name
      </Button>
    </Card>
  )
}

function PhoneSection({ phone, verified }: { phone: string | null; verified: boolean }) {
  const [value, setValue] = useState(phone ?? '')
  const [step, setStep] = useState<'idle' | 'code_sent'>('idle')
  const [code, setCode] = useState('')
  const [error, setError] = useState<string | null>(null)
  const requestOtp = useRequestPhoneOtp()
  const verifyOtp = useVerifyPhoneOtp()

  const handleRequest = () => {
    setError(null)
    requestOtp.mutate(value.trim(), {
      onSuccess: () => setStep('code_sent'),
      onError: (e) => setError(getErrorMessage(e)),
    })
  }

  const handleVerify = () => {
    setError(null)
    verifyOtp.mutate(
      { phone: value.trim(), code: code.trim() },
      {
        onSuccess: () => { setStep('idle'); setCode('') },
        onError: (e) => setError(getErrorMessage(e)),
      },
    )
  }

  return (
    <Card className="flex flex-col gap-3 p-4">
      <h2 className="flex items-center gap-2 font-display text-base font-semibold text-ink-900">
        <Phone className="h-4 w-4 text-trust-700" /> Phone verification
        {verified && (
          <Badge tone="success">
            <ShieldCheck className="h-3 w-3" /> Verified
          </Badge>
        )}
      </h2>
      <p className="text-sm text-ink-700/70">
        A verified phone number earns trust points and lets buyers message you on WhatsApp directly from your listings.
      </p>

      <Input
        label="Phone number"
        placeholder="e.g. 98XXXXXXXX"
        value={value}
        disabled={step === 'code_sent'}
        onChange={(e) => setValue(e.target.value)}
      />

      {step === 'code_sent' && (
        <Input
          label="Verification code"
          placeholder="6-digit code"
          value={code}
          onChange={(e) => setCode(e.target.value)}
        />
      )}

      {error && <p className="text-sm text-danger-600">{error}</p>}

      <div className="flex gap-2">
        {step === 'idle' ? (
          <Button size="sm" isLoading={requestOtp.isPending} disabled={!value.trim()} onClick={handleRequest}>
            {verified && value.trim() === phone ? 'Re-verify this number' : 'Send verification code'}
          </Button>
        ) : (
          <>
            <Button size="sm" isLoading={verifyOtp.isPending} disabled={!code.trim()} onClick={handleVerify}>
              Confirm code
            </Button>
            <Button size="sm" variant="outline" onClick={() => { setStep('idle'); setCode(''); setError(null) }}>
              Cancel
            </Button>
          </>
        )}
      </div>
    </Card>
  )
}

function PasswordSection() {
  const [currentPassword, setCurrentPassword] = useState('')
  const [password, setPassword] = useState('')
  const [confirmation, setConfirmation] = useState('')
  const [saved, setSaved] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const update = useUpdatePassword()

  const handleSubmit = () => {
    setError(null)
    setSaved(false)
    update.mutate(
      { current_password: currentPassword, password, password_confirmation: confirmation },
      {
        onSuccess: () => {
          setSaved(true)
          setCurrentPassword('')
          setPassword('')
          setConfirmation('')
        },
        onError: (e) => setError(getErrorMessage(e)),
      },
    )
  }

  return (
    <Card className="flex flex-col gap-3 p-4">
      <h2 className="flex items-center gap-2 font-display text-base font-semibold text-ink-900">
        <KeyRound className="h-4 w-4 text-trust-700" /> Password
      </h2>
      <Input label="Current password" type="password" value={currentPassword} onChange={(e) => setCurrentPassword(e.target.value)} />
      <Input label="New password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} />
      <Input label="Confirm new password" type="password" value={confirmation} onChange={(e) => setConfirmation(e.target.value)} />
      {error && <p className="text-sm text-danger-600">{error}</p>}
      {saved && <p className="text-sm text-success-600">Password updated.</p>}
      <Button
        className="self-start"
        size="sm"
        isLoading={update.isPending}
        disabled={!currentPassword || !password || !confirmation}
        onClick={handleSubmit}
      >
        Update password
      </Button>
    </Card>
  )
}
