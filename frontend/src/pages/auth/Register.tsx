import { zodResolver } from '@hookform/resolvers/zod'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
import { Link, useNavigate } from 'react-router-dom'
import { useRegister } from '../../lib/api/auth'
import { applyServerErrors, getErrorMessage } from '../../lib/api/errors'
import { Input } from '../../components/ui/Input'
import { Button } from '../../components/ui/Button'
import { Card } from '../../components/ui/Card'

const schema = z
  .object({
    name: z.string().min(2, 'Enter your full name'),
    email: z.string().email('Enter a valid email address'),
    password: z.string().min(8, 'At least 8 characters'),
    password_confirmation: z.string(),
  })
  .refine((data) => data.password === data.password_confirmation, {
    message: 'Passwords do not match',
    path: ['password_confirmation'],
  })

type FormValues = z.infer<typeof schema>

export function Register() {
  const registerUser = useRegister()
  const navigate = useNavigate()

  const {
    register,
    handleSubmit,
    setError,
    formState: { errors },
  } = useForm<FormValues>({ resolver: zodResolver(schema) })

  const onSubmit = handleSubmit((values) => {
    registerUser.mutate(values, {
      onSuccess: () => navigate('/dashboard', { replace: true }),
      onError: (error) => {
        if (!applyServerErrors(error, setError)) {
          setError('email', { type: 'server', message: getErrorMessage(error) })
        }
      },
    })
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
