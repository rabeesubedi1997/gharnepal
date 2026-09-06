import type { FieldValues, UseFormSetError, Path } from 'react-hook-form'

interface LaravelValidationError {
  message: string
  errors?: Record<string, string[]>
}

export function getErrorMessage(error: unknown, fallback = 'Something went wrong. Please try again.'): string {
  const body = (error as { response?: { data?: LaravelValidationError } })?.response?.data
  return body?.message ?? fallback
}

/** Maps Laravel's 422 { errors: { field: [msg] } } body onto react-hook-form field errors. */
export function applyServerErrors<T extends FieldValues>(error: unknown, setError: UseFormSetError<T>): boolean {
  const body = (error as { response?: { status?: number; data?: LaravelValidationError } })?.response
  if (body?.status !== 422 || !body.data?.errors) return false

  for (const [field, messages] of Object.entries(body.data.errors)) {
    setError(field as Path<T>, { type: 'server', message: messages[0] })
  }
  return true
}
