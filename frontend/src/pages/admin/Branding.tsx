import { useRef, useState } from 'react'
import { Palette } from 'lucide-react'
import { useAdminBranding, useUpdateBranding } from '../../lib/api/branding'
import { getErrorMessage } from '../../lib/api/errors'
import { AdminPageHeader } from '../../components/admin/AdminPageHeader'
import { Card } from '../../components/ui/Card'
import { Button } from '../../components/ui/Button'
import { Input } from '../../components/ui/Input'
import { ErrorState } from '../../components/ui/ErrorState'
import { Skeleton } from '../../components/ui/Skeleton'

export function Branding() {
  const { data, isPending, isError, refetch } = useAdminBranding()
  const update = useUpdateBranding()

  const [siteName, setSiteName] = useState('')
  const [favicon, setFavicon] = useState<File | null>(null)
  const [appIcon, setAppIcon] = useState<File | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [saved, setSaved] = useState(false)
  const faviconRef = useRef<HTMLInputElement>(null)
  const appIconRef = useRef<HTMLInputElement>(null)

  const nameValue = siteName || data?.site_name || ''

  const handleSave = () => {
    setError(null)
    setSaved(false)
    update.mutate(
      {
        site_name: siteName.trim() || undefined,
        favicon: favicon ?? undefined,
        app_icon: appIcon ?? undefined,
      },
      {
        onSuccess: () => {
          setSaved(true)
          setSiteName('')
          setFavicon(null)
          setAppIcon(null)
          if (faviconRef.current) faviconRef.current.value = ''
          if (appIconRef.current) appIconRef.current.value = ''
        },
        onError: (e) => setError(getErrorMessage(e)),
      },
    )
  }

  if (isPending) {
    return (
      <div className="flex flex-col gap-6">
        <AdminPageHeader icon={Palette} title="Branding" description="Site name, favicon, and mobile app icon." />
        <Skeleton className="h-64 w-full" />
      </div>
    )
  }

  return (
    <div className="flex flex-col gap-6">
      <AdminPageHeader
        icon={Palette}
        title="Branding"
        description="Site name and icons — no code changes or deploy needed for the website."
      />

      {isError && <ErrorState onRetry={refetch} />}

      <Card className="flex flex-col gap-5 p-4">
        <div>
          <Input
            label="Site name"
            placeholder={data?.site_name ?? 'Ghar Nepal'}
            value={nameValue}
            onChange={(e) => setSiteName(e.target.value)}
          />
          <p className="mt-1 text-xs text-ink-700/60">Shown in the header, footer, and browser tab title — updates live.</p>
        </div>

        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2">
          <div className="flex flex-col gap-2">
            <span className="text-sm font-medium text-ink-900">Website favicon</span>
            <div className="flex items-center gap-3">
              <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg border border-stone-200 bg-stone-50">
                {data?.favicon_url ? (
                  <img src={data.favicon_url} alt="Current favicon" className="h-8 w-8 object-contain" />
                ) : (
                  <span className="text-[10px] text-ink-700/40">default</span>
                )}
              </div>
              <input
                ref={faviconRef}
                type="file"
                accept="image/png,image/x-icon,image/svg+xml,image/webp"
                onChange={(e) => setFavicon(e.target.files?.[0] ?? null)}
                className="min-w-0 flex-1 rounded-lg border border-stone-200 px-3 py-2 text-xs"
              />
            </div>
            <p className="text-xs text-ink-700/60">Square PNG/ICO/SVG, up to 1MB. Applies to every visitor's browser tab immediately.</p>
          </div>

          <div className="flex flex-col gap-2">
            <span className="text-sm font-medium text-ink-900">Mobile app icon</span>
            <div className="flex items-center gap-3">
              <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg border border-stone-200 bg-stone-50">
                {data?.app_icon_url ? (
                  <img src={data.app_icon_url} alt="Current app icon" className="h-full w-full rounded-lg object-cover" />
                ) : (
                  <span className="text-[10px] text-ink-700/40">none</span>
                )}
              </div>
              <input
                ref={appIconRef}
                type="file"
                accept="image/png,image/jpeg"
                onChange={(e) => setAppIcon(e.target.files?.[0] ?? null)}
                className="min-w-0 flex-1 rounded-lg border border-stone-200 px-3 py-2 text-xs"
              />
            </div>
            <p className="text-xs text-ink-700/60">
              Square PNG/JPG, ideally 1024×1024, no transparency. This becomes the source image the mobile team builds the next
              Android/Play Store release from — an app's home-screen icon is baked in at build time, so uploading here does not
              change it on phones that already have the app installed until the next release ships.
            </p>
          </div>
        </div>

        {error && <p className="text-sm text-danger-600">{error}</p>}
        {saved && <p className="text-sm text-success-600">Saved.</p>}
        <Button className="self-start" isLoading={update.isPending} onClick={handleSave}>
          Save branding
        </Button>
      </Card>
    </div>
  )
}
