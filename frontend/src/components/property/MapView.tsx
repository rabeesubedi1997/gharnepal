import { useMemo } from 'react'
import { MapContainer, Marker, Popup, TileLayer } from 'react-leaflet'
import L from 'leaflet'
import { Link } from 'react-router-dom'
import { formatNprCompact } from '../../design-system/tokens'
import type { ListingSummary } from '../../lib/api/listings'

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

export function MapView({ listings }: { listings: ListingSummary[] }) {
  const points = useMemo(
    () => listings.filter((l) => l.location?.lat != null && l.location?.lng != null),
    [listings],
  )

  const center: [number, number] = points.length
    ? [points[0].location!.lat as number, points[0].location!.lng as number]
    : DEFAULT_CENTER

  return (
    <div className="h-[600px] w-full overflow-hidden rounded-card border border-stone-200">
      <MapContainer center={center} zoom={points.length ? 12 : 11} className="h-full w-full" scrollWheelZoom>
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
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
