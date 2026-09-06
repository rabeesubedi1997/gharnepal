import { useEffect, useRef, useState } from 'react'
import { FileText, ShieldCheck, X } from 'lucide-react'
import { useMyVerifications, useSubmitVerification, type VerificationType } from '../lib/api/verifications'
import { getErrorMessage } from '../lib/api/errors'
import { Card } from '../components/ui/Card'
import { Badge } from '../components/ui/Badge'
import { Button } from '../components/ui/Button'
import { Select } from '../components/ui/Input'
import { ErrorState } from '../components/ui/ErrorState'
import { PropertyGridSkeleton } from '../components/ui/Skeleton'

const TYPE_LABEL: Record<VerificationType, string> = {
  identity: 'Identity document (citizenship/passport)',
  agent_license: 'Agent license',
  agency_document: 'Agency registration document',
}

const STATUS_TONE = { pending: 'warning', approved: 'success', rejected: 'danger' } as const

const MAX_SIZE_BYTES = 10 * 1024 * 1024

function formatFileSize(bytes: number): string {
  if (bytes < 1024 * 1024) return `${Math.max(1, Math.round(bytes / 1024))} KB`
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`
}

export function VerificationCenter() {
  const { data: verifications, isPending, isError, refetch } = useMyVerifications()
  const submit = useSubmitVerification()
  const [type, setType] = useState<VerificationType>('identity')
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [previewUrl, setPreviewUrl] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  // Revoke the object URL whenever it's replaced or the component unmounts,
  // so we don't leak memory across repeated selections.
  useEffect(() => {
    return () => {
      if (previewUrl) URL.revokeObjectURL(previewUrl)
    }
  }, [previewUrl])

  const resetSelection = () => {
    if (previewUrl) URL.revokeObjectURL(previewUrl)
    setSelectedFile(null)
    setPreviewUrl(null)
    if (inputRef.current) inputRef.current.value = ''
  }

  const handleFile = (file: File | undefined) => {
    if (!file) return
    setError(null)

    if (file.size > MAX_SIZE_BYTES) {
      setError('That file is larger than 10MB — please choose a smaller one.')
      if (inputRef.current) inputRef.current.value = ''
      return
    }

    if (previewUrl) URL.revokeObjectURL(previewUrl)
    setSelectedFile(file)
    setPreviewUrl(file.type.startsWith('image/') ? URL.createObjectURL(file) : null)
  }

  const handleSubmit = () => {
    if (!selectedFile) return
    setError(null)
    submit.mutate(
      { type, document: selectedFile },
      {
        onError: (e) => setError(getErrorMessage(e)),
        onSuccess: () => resetSelection(),
      },
    )
  }

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="flex items-center gap-2 font-display text-2xl font-semibold text-ink-900">
          <ShieldCheck className="h-6 w-6 text-trust-700" /> Verification center
        </h1>
        <p className="mt-1 text-sm text-ink-700/70">
          Verified owners and agents earn more trust from buyers. Submit a document below for admin review.
        </p>
      </div>

      <Card className="flex flex-col gap-3 p-4">
        <Select label="Document type" value={type} onChange={(e) => setType(e.target.value as VerificationType)}>
          {Object.entries(TYPE_LABEL).map(([value, label]) => (
            <option key={value} value={value}>{label}</option>
          ))}
        </Select>

        {!selectedFile ? (
          <label className="flex cursor-pointer flex-col items-center gap-2 rounded-card border-2 border-dashed border-stone-200 px-6 py-8 text-center hover:border-trust-700">
            <span className="text-sm font-medium text-ink-900">Click to upload a document</span>
            <span className="text-xs text-ink-700/60">JPG, PNG, or PDF — up to 10MB</span>
            <input
              ref={inputRef}
              type="file"
              accept="image/jpeg,image/png,application/pdf"
              className="sr-only"
              onChange={(e) => handleFile(e.target.files?.[0])}
            />
          </label>
        ) : (
          <div className="flex flex-col gap-3 rounded-card border border-stone-200 p-4">
            <div className="flex items-start justify-between gap-3">
              <p className="text-sm font-medium text-ink-900">Preview — review before submitting</p>
              <button
                type="button"
                onClick={resetSelection}
                disabled={submit.isPending}
                aria-label="Remove selected file and choose a different one"
                className="rounded-md p-1 text-ink-700/60 hover:bg-stone-100 hover:text-danger-600 disabled:opacity-50"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            {previewUrl ? (
              <img src={previewUrl} alt="Selected document preview" className="max-h-72 w-full rounded-lg border border-stone-100 object-contain" />
            ) : (
              <div className="flex items-center gap-2 rounded-lg border border-stone-100 bg-stone-50 p-3">
                <FileText className="h-8 w-8 shrink-0 text-ink-700/50" aria-hidden="true" />
                <span className="text-sm text-ink-900">PDF document selected — no preview available for this file type.</span>
              </div>
            )}
            <p className="truncate text-xs text-ink-700/60">
              {selectedFile.name} · {formatFileSize(selectedFile.size)}
            </p>

            <div className="flex gap-2">
              <Button className="flex-1" isLoading={submit.isPending} onClick={handleSubmit}>
                Submit for review
              </Button>
              <Button variant="outline" disabled={submit.isPending} onClick={resetSelection}>
                Choose a different file
              </Button>
            </div>
          </div>
        )}
        {error && <p className="text-sm text-danger-600">{error}</p>}
      </Card>

      <div>
        <h2 className="mb-3 font-display text-lg font-semibold text-ink-900">Your submissions</h2>
        {isPending && <PropertyGridSkeleton count={2} />}
        {isError && <ErrorState onRetry={refetch} />}
        {!isPending && !isError && verifications?.length === 0 && (
          <p className="text-sm text-ink-700/60">No documents submitted yet.</p>
        )}
        <div className="flex flex-col gap-2">
          {verifications?.map((v) => (
            <Card key={v.id} className="flex items-center justify-between gap-3 p-3">
              <div>
                <p className="text-sm font-medium text-ink-900">{TYPE_LABEL[v.type]}</p>
                {v.rejection_reason && <p className="text-xs text-danger-600">{v.rejection_reason}</p>}
              </div>
              <Badge tone={STATUS_TONE[v.status]}>{v.status}</Badge>
            </Card>
          ))}
        </div>
      </div>
    </div>
  )
}
