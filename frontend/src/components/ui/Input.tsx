import { type InputHTMLAttributes, type SelectHTMLAttributes, forwardRef } from 'react'
import { clsx } from 'clsx'

interface FieldWrapperProps {
  label?: string
  error?: string
  hint?: string
  id?: string
}

function FieldChrome({
  label,
  error,
  hint,
  id,
  children,
}: FieldWrapperProps & { children: React.ReactNode }) {
  return (
    <div className="flex flex-col gap-1.5">
      {label && (
        <label htmlFor={id} className="text-sm font-medium text-ink-900">
          {label}
        </label>
      )}
      {children}
      {error ? (
        <p className="text-sm text-danger-600">{error}</p>
      ) : hint ? (
        <p className="text-sm text-ink-700/70">{hint}</p>
      ) : null}
    </div>
  )
}

type InputProps = InputHTMLAttributes<HTMLInputElement> & FieldWrapperProps

export const Input = forwardRef<HTMLInputElement, InputProps>(function Input(
  { label, error, hint, id, className, ...props },
  ref,
) {
  return (
    <FieldChrome label={label} error={error} hint={hint} id={id}>
      <input
        ref={ref}
        id={id}
        aria-invalid={!!error}
        className={clsx(
          'h-10 rounded-lg border bg-white px-3 text-sm text-ink-900 placeholder:text-ink-700/50',
          'focus:outline-none focus:ring-2 focus:ring-offset-1',
          error
            ? 'border-danger-600 focus:ring-danger-600'
            : 'border-stone-200 focus:ring-trust-700',
          className,
        )}
        {...props}
      />
    </FieldChrome>
  )
})

type SelectProps = SelectHTMLAttributes<HTMLSelectElement> & FieldWrapperProps

export const Select = forwardRef<HTMLSelectElement, SelectProps>(function Select(
  { label, error, hint, id, className, children, ...props },
  ref,
) {
  return (
    <FieldChrome label={label} error={error} hint={hint} id={id}>
      <select
        ref={ref}
        id={id}
        aria-invalid={!!error}
        className={clsx(
          'h-10 rounded-lg border bg-white px-3 text-sm text-ink-900',
          'focus:outline-none focus:ring-2 focus:ring-offset-1',
          error
            ? 'border-danger-600 focus:ring-danger-600'
            : 'border-stone-200 focus:ring-trust-700',
          className,
        )}
        {...props}
      >
        {children}
      </select>
    </FieldChrome>
  )
})
