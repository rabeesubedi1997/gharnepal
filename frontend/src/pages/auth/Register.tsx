import { useState } from 'react'
import { zodResolver } from '@hookform/resolvers/zod'
import { useForm } from 'react-hook-form'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { useRegister } from '../../lib/api/auth'
import { useCaptchaConfig } from '../../lib/api/security'
import { applyServerErrors, getErrorMessage } from '../../lib/api/errors'
import { registerSchema, type RegisterValues } from '../../lib/auth/schemas'
import { Input } from '../../components/ui/Input'
import { Button } from '../../components/ui/Button'
import { Card } from '../../components/ui/Card'
import { Recaptcha } from '../../components/auth/Recaptcha'

export function Register() {
  const registerUser = useRegister()
  const { data: captcha } = useCaptchaConfig()
  const navigate = useNavigate()
  const location = useLocation()
  // Same redirect-back Login already does — a guest who lands here via a
  // gated action (rather than the inline AuthModal) doesn't lose it.
  const from = (location.state as { from?: Location })?.from?.pathname ?? '/dashboard'

  const [captchaToken, setCaptchaToken] = useState<string | null>(null)
  const [captchaError, setCaptchaError] = useState<string | null>(null)

  const {
    register,
    handleSubmit,
    setError,
    formState: { errors },
  } = useForm<RegisterValues>({ resolver: zodResolver(registerSchema) })

  const onSubmit = handleSubmit((values) => {
    if (captcha?.enabled && !captchaToken) {
      setCaptchaError('Please complete the "I\'m not a robot" check.')
      return
    }
    setCaptchaError(null)
    registerUser.mutate(
      { ...values, captcha_token: captchaToken ?? undefined },
      {
        onSuccess: () => navigate(from, { replace: true }),
        onError: (error) => {
          // A rejected/expired token is reported under captcha_token, not a
          // form field — surface it next to the widget and make the user
          // re-verify (the token is single-use regardless).
          const captchaMessage = (error as { response?: { data?: { errors?: Record<string, string[]> } } })?.response?.data
            ?.errors?.captcha_token?.[0]
          if (captchaMessage) {
            setCaptchaToken(null)
            setCaptchaError(captchaMessage)
            return
          }
          if (!applyServerErrors(error, setError)) {
            setError('email', { type: 'server', message: getErrorMessage(error) })
          }
        },
      },
    )
  })

  return (
    <div className="mx-auto flex max-w-md flex-col gap-6 py-10">
      <div className="text-center">
        <h1 className="font-display text-2xl font-semibold text-ink-900">Create your account</h1>
        <p className="mt-1 text-sm text-ink-700/70">Save properties, message owners, and post your own listings.</p>
      </div>
      <Card className="p-6">
        <form onSubmit={onSubmit} className="flex flex-col gap-4">
          <Input label="Full name" autoComplete="name" error={errors.name?.message} {...register('name')} />
          <Input label="Email" type="email" autoComplete="email" error={errors.email?.message} {...register('email')} />
          <Input
            label="Password"
            type="password"
            autoComplete="new-password"
            error={errors.password?.message}
            {...register('password')}
          />
          <Input
            label="Confirm password"
            type="password"
            autoComplete="new-password"
            error={errors.password_confirmation?.message}
            {...register('password_confirmation')}
          />
          {captcha?.enabled && captcha.site_key && (
            <div>
              <Recaptcha siteKey={captcha.site_key} onVerify={setCaptchaToken} />
              {captchaError && <p className="mt-1 text-sm text-danger-600">{captchaError}</p>}
            </div>
          )}
          <Button type="submit" isLoading={registerUser.isPending} className="mt-2">
            Create account
          </Button>
        </form>
      </Card>
      <p className="text-center text-sm text-ink-700/70">
        Already have an account?{' '}
        <Link to="/login" className="font-medium text-link-600 hover:text-link-700">
          Log in
        </Link>
      </p>
    </div>
  )
}
