import { AlertTriangle, Check, HelpCircle, Landmark, X } from 'lucide-react'
import { Badge } from '../ui/Badge'
import type { LandProfile } from '../../lib/api/landProfile'

const VERIFICATION_LABEL: Record<LandProfile['document_verification_status'], { text: string; tone: 'neutral' | 'warning' | 'success' }> = {
  unverified: { text: 'Not yet reviewed by admin', tone: 'neutral' },
  partial: { text: 'Partially reviewed by admin', tone: 'warning' },
  verified: { text: 'Documents reviewed by admin', tone: 'success' },
}

function StatusRow({ label, status, detail }: { label: string; status: 'good' | 'bad' | 'unknown'; detail?: string }) {
  const icon =
    status === 'good' ? (
      <Check className="h-4 w-4 text-success-600" aria-hidden="true" />
    ) : status === 'bad' ? (
      <X className="h-4 w-4 text-danger-600" aria-hidden="true" />
    ) : (
      <HelpCircle className="h-4 w-4 text-ink-700/40" aria-hidden="true" />
    )

  return (
    <div className="flex items-center justify-between gap-3 border-b border-stone-100 py-2 last:border-0">
      <span className="flex items-center gap-2 text-sm text-ink-900">
        {icon} {label}
      </span>
      {detail && <span className="text-sm text-ink-700/70">{detail}</span>}
    </div>
  )
}

const RISK_LABEL: Record<string, string> = { none: 'None', low: 'Low', medium: 'Medium', high: 'High', unknown: 'Unknown' }

export function LandDueDiligenceChecklist({ profile }: { profile: LandProfile }) {
  const verification = VERIFICATION_LABEL[profile.document_verification_status]
  const hasHighRisk = profile.flood_risk === 'high' || profile.landslide_risk === 'high'

  return (
    <div className="rounded-card border border-stone-200 p-4">
      <div className="mb-3 flex items-center justify-between gap-2">
        <h2 className="flex items-center gap-2 font-display text-lg font-semibold text-ink-900">
          <Landmark className="h-5 w-5 text-trust-700" aria-hidden="true" /> Land due-diligence
        </h2>
        <Badge tone={verification.tone}>{verification.text}</Badge>
      </div>

      {hasHighRisk && (
        <div className="mb-3 flex items-start gap-2 rounded-lg bg-danger-100 p-3 text-sm text-danger-600">
          <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" aria-hidden="true" />
          <span>This land has a reported flood or landslide risk — please review carefully before proceeding.</span>
        </div>
      )}

      <StatusRow label="Kitta number" status={profile.kitta_number ? 'good' : 'unknown'} detail={profile.kitta_number ?? 'Not provided'} />
      <StatusRow
        label="Lalpurja (land ownership certificate)"
        status={profile.lalpurja_available === 'yes' ? 'good' : profile.lalpurja_available === 'no' ? 'bad' : 'unknown'}
        detail={profile.lalpurja_available === 'in_process' ? 'In process' : profile.lalpurja_available === 'unknown' ? undefined : profile.lalpurja_available}
      />
      <StatusRow
        label="Road access"
        status={profile.road_access ? 'good' : 'bad'}
        detail={profile.road_access ? `${profile.road_type}${profile.road_width_meters ? `, ${profile.road_width_meters}m wide` : ''}` : undefined}
      />
      <StatusRow label="Water access" status={profile.water_access === 'unknown' ? 'unknown' : profile.water_access === 'none' ? 'bad' : 'good'} detail={profile.water_access !== 'unknown' ? profile.water_access : undefined} />
      <StatusRow label="Electricity access" status={profile.electricity_access ? 'good' : 'bad'} />
      <StatusRow label="Drainage" status={profile.drainage_access === 'yes' ? 'good' : profile.drainage_access === 'no' ? 'bad' : 'unknown'} />
      <StatusRow label="Land classification" status="unknown" detail={profile.land_classification} />
      <StatusRow label="Flood risk" status={profile.flood_risk === 'none' ? 'good' : profile.flood_risk === 'unknown' ? 'unknown' : 'bad'} detail={RISK_LABEL[profile.flood_risk]} />
      <StatusRow label="Landslide risk" status={profile.landslide_risk === 'none' ? 'good' : profile.landslide_risk === 'unknown' ? 'unknown' : 'bad'} detail={RISK_LABEL[profile.landslide_risk]} />

      {profile.nearby_development_notes && (
        <div className="mt-3 border-t border-stone-100 pt-3">
          <p className="text-xs font-medium uppercase tracking-wide text-ink-700/50">Nearby development</p>
          <p className="mt-1 text-sm text-ink-700/80">{profile.nearby_development_notes}</p>
        </div>
      )}

      {profile.lalpurja_document_url && (
        <a
          href={profile.lalpurja_document_url}
          target="_blank"
          rel="noreferrer"
          className="mt-3 inline-block text-sm font-medium text-link-600 hover:text-link-700"
        >
          View submitted lalpurja document →
        </a>
      )}

      <p className="mt-3 border-t border-stone-100 pt-2 text-xs text-ink-700/50">
        Owner-submitted information, reviewed by an admin for plausibility — not a government
        land-registry confirmation. Always verify official documents independently before any transaction.
      </p>
    </div>
  )
}
