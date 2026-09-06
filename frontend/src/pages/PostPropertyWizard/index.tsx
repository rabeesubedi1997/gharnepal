import { useState } from 'react'
import { z } from 'zod'
import { CheckCircle2 } from 'lucide-react'
import { useCreateProperty } from '../../lib/api/properties'
import { useCreateListing, useTransitionListing, type MediaItem } from '../../lib/api/listings'
import { useSaveLandProfile, type LandProfileInput } from '../../lib/api/landProfile'
import { getErrorMessage } from '../../lib/api/errors'
import { ErrorState } from '../../components/ui/ErrorState'
import { ButtonLink } from '../../components/ui/Button'
import { BasicsStep } from './BasicsStep'
import { LocationStep } from './LocationStep'
import { LandDetailsStep } from './LandDetailsStep'
import { MediaStep } from './MediaStep'
import { PricingStep } from './PricingStep'
import { ReviewStep } from './ReviewStep'
import { type AddressState, type BasicsState, type PricingState, RESIDENTIAL_TYPES, initialAddress, initialBasics, initialPricing } from './types'

const basicsSchema = z.object({
  property_type: z.enum(['room', 'apartment', 'house', 'land', 'commercial'], { message: 'Select a property type' }),
  area_value: z.coerce.number({ message: 'Enter the area' }).positive('Enter a valid area'),
  bedrooms: z.string().optional(),
  bathrooms: z.string().optional(),
})

const addressSchema = z.object({
  province_id: z.number({ message: 'Required' }),
  district_id: z.number({ message: 'Required' }),
  municipality_id: z.number({ message: 'Required' }),
  ward_id: z.number({ message: 'Required' }),
})

const pricingSchema = z.object({
  title: z.string().min(5, 'Give your listing a descriptive title'),
  purpose: z.enum(['sale', 'rent'], { message: 'Select a purpose' }),
  price: z.coerce.number({ message: 'Enter a price' }).positive('Enter a valid price'),
  price_period: z.string().optional(),
})

export function PostPropertyWizard() {
  const [step, setStep] = useState(0)
  const [basics, setBasics] = useState<BasicsState>(initialBasics)
  const [address, setAddress] = useState<AddressState>(initialAddress)
  const [landProfile, setLandProfile] = useState<LandProfileInput>({})
  const [pricing, setPricing] = useState<PricingState>(initialPricing)
  const [propertyId, setPropertyId] = useState<number | null>(null)
  const [media, setMedia] = useState<MediaItem[]>([])
  const [listingId, setListingId] = useState<number | null>(null)
  const [done, setDone] = useState<'draft' | 'submitted' | null>(null)

  const [basicsErrors, setBasicsErrors] = useState<Partial<Record<keyof BasicsState, string>>>({})
  const [addressErrors, setAddressErrors] = useState<Partial<Record<string, string>>>({})
  const [pricingErrors, setPricingErrors] = useState<Partial<Record<keyof PricingState, string>>>({})
  const [stepError, setStepError] = useState<string | null>(null)

  const createProperty = useCreateProperty()
  const saveLandProfile = useSaveLandProfile()
  const createListing = useCreateListing()
  const transition = useTransitionListing()

  const isResidential = RESIDENTIAL_TYPES.includes(basics.property_type as never)
  const isLand = basics.property_type === 'land'

  // Land listings get one extra step ("Land details") right after Location.
  const STEPS = isLand
    ? ['Basics', 'Location', 'Land details', 'Photos', 'Pricing', 'Review']
    : ['Basics', 'Location', 'Photos', 'Pricing', 'Review']
  const STEP_MEDIA = isLand ? 3 : 2
  const STEP_PRICING = isLand ? 4 : 3
  const STEP_REVIEW = isLand ? 5 : 4

  const handleBasicsNext = () => {
    const result = basicsSchema.safeParse(basics)
    if (!result.success) {
      setBasicsErrors(Object.fromEntries(result.error.issues.map((i) => [i.path[0], i.message])))
      return
    }
    if (isResidential && (!basics.bedrooms || !basics.bathrooms)) {
      setBasicsErrors({
        bedrooms: !basics.bedrooms ? 'Required for this property type' : undefined,
        bathrooms: !basics.bathrooms ? 'Required for this property type' : undefined,
      })
      return
    }
    setBasicsErrors({})
    setStep(1)
  }

  const handleLocationNext = () => {
    const result = addressSchema.safeParse(address)
    if (!result.success) {
      setAddressErrors(Object.fromEntries(result.error.issues.map((i) => [i.path[0], i.message])))
      return
    }
    setAddressErrors({})
    setStepError(null)

    if (propertyId) {
      setStep(2)
      return
    }

    createProperty.mutate(
      {
        property_type: basics.property_type as never,
        area_value: Number(basics.area_value),
        area_unit: basics.area_unit,
        bedrooms: basics.bedrooms ? Number(basics.bedrooms) : undefined,
        bathrooms: basics.bathrooms ? Number(basics.bathrooms) : undefined,
        floors: basics.floors ? Number(basics.floors) : undefined,
        year_built: basics.year_built ? Number(basics.year_built) : undefined,
        parking_spaces: basics.parking_spaces ? Number(basics.parking_spaces) : undefined,
        parking_type: basics.parking_type || undefined,
        is_furnished: basics.is_furnished || undefined,
        address: {
          province_id: address.province_id!,
          district_id: address.district_id!,
          municipality_id: address.municipality_id!,
          ward_id: address.ward_id!,
          neighborhood_id: address.neighborhood_id,
          street_address: address.street_address || undefined,
          landmark: address.landmark || undefined,
        },
      },
      {
        onSuccess: (property) => {
          setPropertyId(property.id)
          setStep(2)
        },
        onError: (error) => setStepError(getErrorMessage(error)),
      },
    )
  }

  const handleLandDetailsNext = () => {
    setStepError(null)
    saveLandProfile.mutate(
      { propertyId: propertyId!, input: landProfile },
      {
        onSuccess: () => setStep(STEP_MEDIA),
        onError: (error) => setStepError(getErrorMessage(error)),
      },
    )
  }

  const handlePricingNext = () => {
    const result = pricingSchema.safeParse(pricing)
    if (!result.success) {
      setPricingErrors(Object.fromEntries(result.error.issues.map((i) => [i.path[0], i.message])))
      return
    }
    if (pricing.purpose === 'rent' && !pricing.price_period) {
      setPricingErrors({ price_period: 'Select a price period' })
      return
    }
    setPricingErrors({})
    setStepError(null)

    if (listingId) {
      setStep(STEP_REVIEW)
      return
    }

    createListing.mutate(
      {
        propertyId: propertyId!,
        input: {
          purpose: pricing.purpose as 'sale' | 'rent',
          price: Number(pricing.price),
          price_period: pricing.price_period || undefined,
          negotiable: pricing.negotiable,
          availability_date: pricing.availability_date || undefined,
          title: pricing.title,
          description: pricing.description || undefined,
          amenity_ids: pricing.amenity_ids,
        },
      },
      {
        onSuccess: (listing) => {
          setListingId(listing.id)
          setStep(STEP_REVIEW)
        },
        onError: (error) => setStepError(getErrorMessage(error)),
      },
    )
  }

  const handleFinish = (action: 'submit' | 'stay_draft') => {
    if (action === 'stay_draft') {
      setDone('draft')
      return
    }
    transition.mutate(
      { listingId: listingId!, action: 'submit' },
      {
        onSuccess: () => setDone('submitted'),
        onError: (error) => setStepError(getErrorMessage(error)),
      },
    )
  }

  if (done) {
    return (
      <div className="mx-auto flex max-w-lg flex-col items-center gap-4 py-16 text-center">
        <CheckCircle2 className="h-12 w-12 text-trust-700" aria-hidden="true" />
        <h1 className="font-display text-2xl font-semibold text-ink-900">
          {done === 'submitted' ? 'Submitted for review' : 'Saved as draft'}
        </h1>
        <p className="text-sm text-ink-700/70">
          {done === 'submitted'
            ? "We'll notify you once our team approves your listing."
            : 'Find it anytime in your dashboard to finish and submit it later.'}
        </p>
        <ButtonLink to="/dashboard">Go to dashboard</ButtonLink>
      </div>
    )
  }

  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-6 py-8">
      <div>
        <h1 className="font-display text-2xl font-semibold text-ink-900">Post a property</h1>
        <ol className="mt-4 flex flex-wrap items-center gap-2 text-xs font-medium text-ink-700/60">
          {STEPS.map((label, i) => (
            <li key={label} className={`flex items-center gap-2 ${i === step ? 'text-trust-700' : ''}`}>
              <span
                className={`flex h-6 w-6 items-center justify-center rounded-full border text-[11px] ${
                  i < step ? 'border-trust-700 bg-trust-700 text-white' : i === step ? 'border-trust-700 text-trust-700' : 'border-stone-200'
                }`}
              >
                {i < step ? '✓' : i + 1}
              </span>
              {label}
              {i < STEPS.length - 1 && <span className="mx-1 h-px w-4 bg-stone-200" />}
            </li>
          ))}
        </ol>
      </div>

      {stepError && <ErrorState title="Couldn't save that step" description={stepError} />}

      {step === 0 && (
        <BasicsStep value={basics} onChange={setBasics} errors={basicsErrors} onNext={handleBasicsNext} />
      )}
      {step === 1 && (
        <LocationStep
          value={address}
          onChange={setAddress}
          errors={addressErrors}
          onNext={handleLocationNext}
          onBack={() => setStep(0)}
          isSubmitting={createProperty.isPending}
        />
      )}
      {step === 2 && isLand && (
        <LandDetailsStep
          value={landProfile}
          onChange={setLandProfile}
          onNext={handleLandDetailsNext}
          onBack={() => setStep(1)}
          isSubmitting={saveLandProfile.isPending}
        />
      )}
      {step === STEP_MEDIA && propertyId && (
        <MediaStep
          propertyId={propertyId}
          media={media}
          onMediaAdded={(item) => setMedia((m) => [...m, item])}
          onMediaRemoved={(id) => setMedia((m) => m.filter((item) => item.id !== id))}
          onNext={() => setStep(STEP_PRICING)}
          onBack={() => setStep(isLand ? 2 : 1)}
        />
      )}
      {step === STEP_PRICING && (
        <PricingStep
          value={pricing}
          onChange={setPricing}
          errors={pricingErrors}
          onNext={handlePricingNext}
          onBack={() => setStep(STEP_MEDIA)}
          isSubmitting={createListing.isPending}
        />
      )}
      {step === STEP_REVIEW && (
        <ReviewStep
          basics={basics}
          pricing={pricing}
          onBack={() => setStep(STEP_PRICING)}
          onSubmitForReview={() => handleFinish('submit')}
          onSaveAsDraft={() => handleFinish('stay_draft')}
          isSubmitting={transition.isPending}
        />
      )}
    </div>
  )
}
