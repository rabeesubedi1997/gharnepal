import { useState } from 'react'
import { zodResolver } from '@hookform/resolvers/zod'
import { useForm } from 'react-hook-form'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { useResetPassword } from '../../lib/api/auth'
import { applyServerErrors, getErrorMessage } from '../../lib/api/errors'
import { resetPasswordSchema, type ResetPasswordValues } from '../../lib/auth/schemas'
import { Input } from '../../components/ui/Input'
import { Button } from '../../components/ui/Button'
import { Card } from '../../components/ui/Card'
import { useToast } from '../../components/ui/Toast'

export function ResetPassword() {
  const [searchParams] = useSearchParams()
  const token = searchParams.get('token') ?? ''
  const email = searchParams.get('email') ?? ''
  const navigate = useNavigate()
  const toast = useToast()
  const resetPassword = useResetPassword()
  const [formError, setFormError] = useState<string | null>(null)

  const {
    register,
    handleSubmit,
    setError,
    formState: { errors },
  } = useForm<ResetPasswordValues>({ resolver: zodResolver(resetPasswordSchema) })

  const onSubmit = handleSubmit((values) => {
    setFormError(null)
    resetPassword.mutate(
      { ...values, token, email },
      {
        onSuccess: () => {
          toast.success('Password reset. You can now log in.')
          navigate('/login', { replace: true })
        },
        onError: (error) => {
          if (!applyServerErrors(error, setError)) {
            setFormError(getErrorMessage(error, 'That reset link is invalid or has expired.'))
          }
        },
      },
    )
  })

  if (!token || !email) {
    return (
      <div className="mx-auto flex max-w-md flex-col gap-6 py-10 text-center">
        <h1 className="font-display text-2xl font-semibold text-ink-900">Invalid reset link</h1>
        <p className="text-sm text-ink-700/70">
          This password reset link is missing some information. Request a new one below.
        </p>
        <Link to="/forgot-password" className="font-medium text-link-600 hover:text-link-700">
          Request a new reset link
        </Link>
      </div>
    )
  }

  return (
    <div className="mx-auto flex max-w-md flex-col gap-6 py-10">
      <div className="text-center">
        <h1 className="font-display text-2xl font-semibold text-ink-900">Choose a new password</h1>
        <p className="mt-1 text-sm text-ink-700/70">Resetting the password for {email}.</p>
      </div>
      <Card className="p-6">
        <form onSubmit={onSubmit} className="flex flex-col gap-4">
          {formError && <p className="text-sm text-danger-600">{formError}</p>}
          <Input
            label="New password"
            type="password"
            autoComplete="new-password"
            error={errors.password?.message}
            {...register('password')}
          />
          <Input
            label="Confirm new password"
            type="password"
            autoComplete="new-password"
            error={errors.password_confirmation?.message}
            {...register('password_confirmation')}
          />
          <Button type="submit" isLoading={resetPassword.isPending} className="mt-2">
            Reset password
          </Button>
        </form>
      </Card>
    </div>
  )
}
