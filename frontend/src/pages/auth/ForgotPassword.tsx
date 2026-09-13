import { useState } from 'react'
import { zodResolver } from '@hookform/resolvers/zod'
import { useForm } from 'react-hook-form'
import { Link } from 'react-router-dom'
import { useForgotPassword } from '../../lib/api/auth'
import { getErrorMessage } from '../../lib/api/errors'
import { forgotPasswordSchema, type ForgotPasswordValues } from '../../lib/auth/schemas'
import { Input } from '../../components/ui/Input'
import { Button } from '../../components/ui/Button'
import { Card } from '../../components/ui/Card'

export function ForgotPassword() {
  const forgotPassword = useForgotPassword()
  const [sent, setSent] = useState(false)

  const {
    register,
    handleSubmit,
    setError,
    formState: { errors },
  } = useForm<ForgotPasswordValues>({ resolver: zodResolver(forgotPasswordSchema) })

  const onSubmit = handleSubmit((values) => {
    forgotPassword.mutate(values.email, {
      // The backend always returns the same generic response whether or not
      // the email is registered, so the UI shows the same confirmation
      // either way — never reveals which emails have accounts.
      onSuccess: () => setSent(true),
      onError: (error) => setError('email', { type: 'server', message: getErrorMessage(error, 'Something went wrong. Try again.') }),
    })
  })

  return (
    <div className="mx-auto flex max-w-md flex-col gap-6 py-10">
      <div className="text-center">
        <h1 className="font-display text-2xl font-semibold text-ink-900">Reset your password</h1>
        <p className="mt-1 text-sm text-ink-700/70">Enter your account email and we'll send you a reset link.</p>
      </div>
      <Card className="p-6">
        {sent ? (
          <p className="text-sm text-ink-700/80">
            If an account exists for that email, a password reset link has been sent. Check your inbox (and spam
            folder) for the next step.
          </p>
        ) : (
          <form onSubmit={onSubmit} className="flex flex-col gap-4">
            <Input label="Email" type="email" autoComplete="email" error={errors.email?.message} {...register('email')} />
            <Button type="submit" isLoading={forgotPassword.isPending} className="mt-2">
              Send reset link
            </Button>
          </form>
        )}
      </Card>
      <p className="text-center text-sm text-ink-700/70">
        Remembered it after all?{' '}
        <Link to="/login" className="font-medium text-link-600 hover:text-link-700">
          Back to log in
        </Link>
      </p>
    </div>
  )
}
