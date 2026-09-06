import type { AreaUnit, FurnishedStatus, ParkingType, PropertyType } from '../../lib/api/properties'
import type { AddressValue } from '../../components/property/AddressFields'

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
}

export const RESIDENTIAL_TYPES: PropertyType[] = ['room', 'apartment', 'house']

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
}

export interface AddressState extends AddressValue {
  street_address: string
  landmark: string
}

export const initialAddress: AddressState = {
  street_address: '',
  landmark: '',
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
}
