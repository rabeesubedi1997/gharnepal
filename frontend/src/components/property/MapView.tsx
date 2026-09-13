import { useMemo, useState } from 'react'
import { MapContainer, Marker, Polygon, Popup, TileLayer, useMapEvents } from 'react-leaflet'
import L from 'leaflet'
import { Link } from 'react-router-dom'
import { LassoSelect, X } from 'lucide-react'
import { formatNprCompact } from '../../design-system/tokens'
import type { ListingSummary } from '../../lib/api/listings'
import { Button } from '../ui/Button'

// Default Leaflet marker icons reference files that don't resolve under Vite's
// bundler; point them at the CDN copies instead of shipping broken markers.
const markerIcon = new L.Icon({
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
})

// Kathmandu Valley — sensible default center when no listing has coordinates yet.
const DEFAULT_CENTER: [number, number] = [27.7172, 85.324]

const DRAWN_AREA_STYLE = { color: '#1f4b3f', weight: 2, fillOpacity: 0.1 }
const DRAFT_AREA_STYLE = { color: '#1f4b3f', weight: 2, dashArray: '6', fillOpacity: 0.05 }

interface MapViewProps {
  listings: ListingSummary[]
  /** Only the Search page's map tab offers "search this area" — a listing's
   * own single-pin location map (ListingDetail) has nothing to draw around. */
  drawEnabled?: boolean
  /** The active search polygon, if any — kept in the parent (and the URL)
   * so it survives a filter change or page reload, not local component state. */
  polygon?: [number, number][]
  onSearchArea?: (points: [number, number][]) => void
  onClearArea?: () => void
}

export function MapView({ listings, drawEnabled, polygon, onSearchArea, onClearArea }: MapViewProps) {
  const [drawing, setDrawing] = useState(false)
  const [draftPoints, setDraftPoints] = useState<[number, number][]>([])

  const points = useMemo(
    () => listings.filter((l) => l.location?.lat != null && l.location?.lng != null),
    [listings],
  )

  const center: [number, number] = points.length
    ? [points[0].location!.lat as number, points[0].location!.lng as number]
    : DEFAULT_CENTER

  const startDrawing = () => {
    setDraftPoints([])
    setDrawing(true)
  }

  const finishDrawing = () => {
    if (draftPoints.length < 3) return
    onSearchArea?.(draftPoints)
    setDrawing(false)
    setDraftPoints([])
  }

  const cancelDrawing = () => {
    setDrawing(false)
    setDraftPoints([])
  }

  return (
    <div className="relative h-[600px] w-full overflow-hidden rounded-card border border-stone-200">
      {drawEnabled && (
        <div className="absolute right-2 top-2 z-[1000] flex flex-col items-end gap-1.5">
          {!drawing && !polygon && (
            <Button size="sm" variant="outline" className="bg-white shadow-sm" onClick={startDrawing}>
              <LassoSelect className="h-3.5 w-3.5" /> Draw search area
            </Button>
          )}
          {drawing && (
            <div className="flex flex-col items-end gap-1.5">
              <p className="rounded-md bg-white/95 px-2 py-1 text-xs text-ink-700/70 shadow-sm">
                Click the map to add points ({draftPoints.length})
              </p>
              <div className="flex gap-1.5">
                <Button size="sm" variant="outline" className="bg-white shadow-sm" onClick={cancelDrawing}>
                  <X className="h-3.5 w-3.5" /> Cancel
                </Button>
                <Button size="sm" className="shadow-sm" disabled={draftPoints.length < 3} onClick={finishDrawing}>
                  Search this area
                </Button>
              </div>
            </div>
          )}
          {polygon && !drawing && (
            <Button size="sm" variant="outline" className="bg-white shadow-sm" onClick={onClearArea}>
              <X className="h-3.5 w-3.5" /> Clear search area
            </Button>
          )}
        </div>
      )}

      <MapContainer center={center} zoom={points.length ? 12 : 11} className="h-full w-full" scrollWheelZoom>
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        {drawing && <DrawClickCapture onPoint={(p) => setDraftPoints((pts) => [...pts, p])} />}
        {drawing && draftPoints.length > 0 && <Polygon positions={draftPoints} pathOptions={DRAFT_AREA_STYLE} />}
        {!drawing && polygon && polygon.length >= 3 && <Polygon positions={polygon} pathOptions={DRAWN_AREA_STYLE} />}
        {points.map((listing) => (
          <Marker
            key={listing.id}
            position={[listing.location!.lat as number, listing.location!.lng as number]}
            icon={markerIcon}
          >
            <Popup>
              <Link to={`/listings/${listing.slug}`} className="font-medium text-link-600">
                {listing.title}
              </Link>
              <p className="mt-1 font-semibold text-trust-700">{formatNprCompact(listing.price)}</p>
            </Popup>
          </Marker>
        ))}
      </MapContainer>
      {points.length === 0 && listings.length > 0 && (
        <p className="relative -mt-10 bg-white/90 px-3 py-1 text-center text-xs text-ink-700/70">
          None of these listings have a map pin yet — showing Kathmandu Valley by default.
        </p>
      )}
    </div>
  )
}

function DrawClickCapture({ onPoint }: { onPoint: (point: [number, number]) => void }) {
  useMapEvents({
    click(e) {
      onPoint([e.latlng.lat, e.latlng.lng])
    },
  })
  return null
}
