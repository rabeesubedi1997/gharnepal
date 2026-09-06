import { type ButtonHTMLAttributes, forwardRef } from 'react'
import { Link, type LinkProps } from 'react-router-dom'
import { clsx } from 'clsx'

type Variant = 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger'
type Size = 'sm' | 'md' | 'lg'

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant
  size?: Size
  isLoading?: boolean
}

export const variantClasses: Record<Variant, string> = {
  primary: 'bg-trust-700 text-white hover:bg-trust-600 focus-visible:outline-trust-700',
  secondary: 'bg-accent-600 text-white hover:bg-accent-500 focus-visible:outline-accent-600',
  outline: 'border border-stone-200 bg-white text-ink-900 hover:bg-stone-100 focus-visible:outline-ink-700',
  ghost: 'text-ink-700 hover:bg-stone-100 focus-visible:outline-ink-700',
  danger: 'bg-danger-600 text-white hover:bg-red-700 focus-visible:outline-danger-600',
}

export const sizeClasses: Record<Size, string> = {
  sm: 'h-8 px-3 text-sm gap-1.5',
  md: 'h-10 px-4 text-sm gap-2',
  lg: 'h-12 px-6 text-base gap-2',
}

export const buttonBaseClasses =
  'inline-flex items-center justify-center rounded-lg font-medium transition-colors ' +
  'focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 ' +
  'disabled:cursor-not-allowed disabled:opacity-50'

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  { variant = 'primary', size = 'md', isLoading, disabled, className, children, ...props },
  ref,
) {
  return (
    <button
      ref={ref}
      disabled={disabled || isLoading}
      className={clsx(buttonBaseClasses, variantClasses[variant], sizeClasses[size], className)}
      {...props}
    >
      {isLoading && (
        <span
          className="h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent"
          aria-hidden="true"
        />
      )}
      {children}
    </button>
  )
})

interface ButtonLinkProps extends LinkProps {
  variant?: Variant
  size?: Size
}

/** Same visual language as <Button>, but renders a router <Link> for navigation. */
export const ButtonLink = forwardRef<HTMLAnchorElement, ButtonLinkProps>(function ButtonLink(
  { variant = 'primary', size = 'md', className, children, ...props },
  ref,
) {
  return (
    <Link
      ref={ref}
      className={clsx(buttonBaseClasses, variantClasses[variant], sizeClasses[size], className)}
      {...props}
    >
      {children}
    </Link>
  )
})
