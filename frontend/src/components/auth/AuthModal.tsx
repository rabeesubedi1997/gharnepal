import { useState } from 'react'
import { zodResolver } from '@hookform/resolvers/zod'
import { useForm } from 'react-hook-form'
import { useLogin, useRegister } from '../../lib/api/auth'
import { applyServerErrors, getErrorMessage } from '../../lib/api/errors'
import { loginSchema, registerSchema, type LoginValues, type RegisterValues } from '../../lib/auth/schemas'
import { Modal } from '../ui/Modal'
import { Input } from '../ui/Input'
import { Button } from '../ui/Button'

interface AuthModalProps {
  open: boolean
  message?: string
  onClose: () => void
  /** Called once login/register succeeds — the caller resumes whatever
   * action was gated (opening a message/viewing/rating modal, etc.). */
  onAuthenticated: () => void
}

/** The inline alternative to navigating to /login or /register. Whatever the
 * user was doing (a half-typed message, an open modal) stays on screen —
 * this just layers a compact login/register form on top and hands control
 * straight back on success, with no page navigation either way. */
export function AuthModal({ open, message, onClose, onAuthenticated }: AuthModalProps) {
  const [mode, setMode] = useState<'login' | 'register'>('login')

  const handleClose = () => {
    setMode('login')
    onClose()
  }

  return (
    <Modal open={open} onClose={handleClose} title={mode === 'login' ? 'Log in to continue' : 'Create your account'}>
      <div className="flex flex-col gap-4">
        {message && <p className="text-sm text-ink-700/70">{message}</p>}
        {mode === 'login' ? (
          <LoginForm onSuccess={onAuthenticated} />
        ) : (
          <RegisterForm onSuccess={onAuthenticated} />
        )}
        <p className="text-center text-sm text-ink-700/70">
          {mode === 'login' ? (
            <>
              New to Ghar Nepal?{' '}
              <button type="button" onClick={() => setMode('register')} className="font-medium text-link-600 hover:text-link-700">
                Create an account
              </button>
            </>
          ) : (
            <>
              Already have an account?{' '}
              <button type="button" onClick={() => setMode('login')} className="font-medium text-link-600 hover:text-link-700">
                Log in
              </button>
            </>
          )}
        </p>
      </div>
    </Modal>
  )
}

function LoginForm({ onSuccess }: { onSuccess: () => void }) {
  const login = useLogin()
  const {
    register,
    handleSubmit,
    setError,
    formState: { errors },
  } = useForm<LoginValues>({ resolver: zodResolver(loginSchema) })

  const onSubmit = handleSubmit((values) => {
    login.mutate(values, {
      onSuccess,
      onError: (error) => {
        if (!applyServerErrors(error, setError)) {
          setError('email', { type: 'server', message: getErrorMessage(error, 'Invalid email or password.') })
        }
      },
    })
  })

  return (
    <form onSubmit={onSubmit} className="flex flex-col gap-3">
      <Input label="Email" type="email" autoComplete="email" error={errors.email?.message} {...register('email')} />
      <Input
        label="Password"
        type="password"
        autoComplete="current-password"
        error={errors.password?.message}
        {...register('password')}
      />
      <Button type="submit" isLoading={login.isPending} className="mt-1">
        Log in
      </Button>
    </form>
  )
}

function RegisterForm({ onSuccess }: { onSuccess: () => void }) {
  const registerUser = useRegister()
  const {
    register,
    handleSubmit,
    setError,
    formState: { errors },
  } = useForm<RegisterValues>({ resolver: zodResolver(registerSchema) })

  const onSubmit = handleSubmit((values) => {
    registerUser.mutate(values, {
      onSuccess,
      onError: (error) => {
        if (!applyServerErrors(error, setError)) {
          setError('email', { type: 'server', message: getErrorMessage(error) })
        }
      },
    })
  })

  return (
    <form onSubmit={onSubmit} className="flex flex-col gap-3">
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
      <Button type="submit" isLoading={registerUser.isPending} className="mt-1">
        Create account
      </Button>
    </form>
  )
}
