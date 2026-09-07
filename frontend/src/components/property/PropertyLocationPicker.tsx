import { useState } from 'react'
import { MapContainer, Marker, TileLayer, useMapEvents } from 'react-leaflet'
import L from 'leaflet'
import { Crosshair, X } from 'lucide-react'
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

// Kathmandu Valley — sensible default center before the owner has picked a spot.
const DEFAULT_CENTER: [number, number] = [27.7172, 85.324]

function ClickCapture({ onPick }: { onPick: (lat: number, lng: number) => void }) {
  useMapEvents({
    click: (e) => onPick(e.latlng.lat, e.latlng.lng),
  })
  return null
}

/**
 * Click-to-pin map for marking a property's exact location (free OpenStreetMap
 * tiles via Leaflet — no paid maps API). Optional: the cascading Province/
 * District/Municipality/Ward picker above this already places the listing on
 * a map at the ward level; this pin is what lets `MapView` show the exact
 * spot on the listing detail page instead of nothing at all.
 */
export function PropertyLocationPicker({
  lat,
  lng,
  onChange,
}: {
  lat: number | null
  lng: number | null
  onChange: (lat: number | null, lng: number | null) => void
}) {
  const [locating, setLocating] = useState(false)
  const [locateError, setLocateError] = useState<string | null>(null)
  const center: [number, number] = lat != null && lng != null ? [lat, lng] : DEFAULT_CENTER

  const useCurrentLocation = () => {
    if (!navigator.geolocation) {
      setLocateError("Your browser doesn't support location detection.")
      return
    }
    setLocating(true)
    setLocateError(null)
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        onChange(pos.coords.latitude, pos.coords.longitude)
        setLocating(false)
      },
      () => {
        setLocateError("Couldn't get your location — pick it on the map instead.")
        setLocating(false)
      },
      { enableHighAccuracy: true, timeout: 10000 },
    )
  }

  return (
    <div className="flex flex-col gap-2">
      <div className="flex items-center justify-between gap-2">
        <label className="text-sm font-medium text-ink-900">Pin exact location on map (optional)</label>
        <div className="flex items-center gap-2">
          {lat != null && (
            <Button type="button" size="sm" variant="ghost" onClick={() => onChange(null, null)}>
              <X className="h-3.5 w-3.5" /> Clear pin
            </Button>
          )}
          <Button type="button" size="sm" variant="outline" isLoading={locating} onClick={useCurrentLocation}>
            <Crosshair className="h-3.5 w-3.5" /> Use my location
          </Button>
        </div>
      </div>
      <p className="text-xs text-ink-700/60">
        Click or tap the map to drop a pin. This is what buyers see on your listing's location map —
        the ward you selected above is used if you skip this.
      </p>
      {locateError && <p className="text-xs text-danger-600">{locateError}</p>}
      <div className="h-64 w-full overflow-hidden rounded-lg border border-stone-200">
        <MapContainer center={center} zoom={lat != null ? 15 : 12} className="h-full w-full" scrollWheelZoom={false}>
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          <ClickCapture onPick={onChange} />
          {lat != null && lng != null && <Marker position={[lat, lng]} icon={markerIcon} />}
        </MapContainer>
      </div>
    </div>
  )
}
