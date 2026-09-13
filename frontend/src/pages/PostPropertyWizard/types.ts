import type { AreaUnit, FacingDirection, FurnishedStatus, ParkingType, PropertyType } from '../../lib/api/properties'
import type { AddressValue } from '../../components/property/AddressFields'

export interface FloorBreakdownRow {
  label: string
  area_sqft: string
  description: string
}

export interface BasicsState {
  property_type: PropertyType | ''
  area_value: string
  area_unit: AreaUnit
  bedrooms: string
  bathrooms: string
  floors: string
  year_built: string
  parking_spaces: string
  parking_type: ParkingType | ''
  is_furnished: FurnishedStatus | ''
  facing_direction: FacingDirection | ''
  water_tank_capacity_liters: string
  structural_notes: string
  floor_breakdown: FloorBreakdownRow[]
}

// A structural/architectural overview only makes sense for a building an
// owner actually constructed — not land, and not a single rented room.
export const RESIDENTIAL_TYPES: PropertyType[] = ['room', 'apartment', 'house']
export const STRUCTURAL_DETAIL_TYPES: PropertyType[] = ['apartment', 'house', 'commercial']

export const initialBasics: BasicsState = {
  property_type: '',
  area_value: '',
  area_unit: 'sqft',
  bedrooms: '',
  bathrooms: '',
  floors: '',
  year_built: '',
  parking_spaces: '',
  parking_type: '',
  is_furnished: '',
  facing_direction: '',
  water_tank_capacity_liters: '',
  structural_notes: '',
  floor_breakdown: [],
}

export interface AddressState extends AddressValue {
  street_address: string
  landmark: string
  lat: number | null
  lng: number | null
}

export const initialAddress: AddressState = {
  street_address: '',
  landmark: '',
  lat: null,
  lng: null,
}

export interface PricingState {
  purpose: 'sale' | 'rent' | ''
  price: string
  price_period: 'total' | 'monthly' | ''
  negotiable: boolean
  availability_date: string
  title: string
  description: string
  amenity_ids: number[]
  video_url: string
}

export const initialPricing: PricingState = {
  purpose: '',
  price: '',
  price_period: '',
  negotiable: false,
  availability_date: '',
  title: '',
  description: '',
  amenity_ids: [],
  video_url: '',
}
