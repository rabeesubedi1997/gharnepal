import { useDistricts, useMunicipalities, useNeighborhoods, useProvinces, useWards } from '../../lib/api/locations'
import { Select } from '../ui/Input'

export interface AddressValue {
  province_id?: number
  district_id?: number
  municipality_id?: number
  ward_id?: number
  neighborhood_id?: number
}

interface AddressFieldsProps {
  value: AddressValue
  onChange: (value: AddressValue) => void
  errors?: Partial<Record<keyof AddressValue, string>>
}

/** Cascading Province -> District -> Municipality -> Ward -> Neighborhood picker. */
export function AddressFields({ value, onChange, errors }: AddressFieldsProps) {
  const { data: provinces, isPending: provincesPending } = useProvinces()
  const { data: districts, isPending: districtsPending } = useDistricts(value.province_id)
  const { data: municipalities, isPending: municipalitiesPending } = useMunicipalities(value.district_id)
  const { data: wards, isPending: wardsPending } = useWards(value.municipality_id)
  const { data: neighborhoods } = useNeighborhoods(value.ward_id)

  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
      <Select
        label="Province"
        value={value.province_id ?? ''}
        error={errors?.province_id}
        disabled={provincesPending}
        onChange={(e) =>
          onChange({ province_id: e.target.value ? Number(e.target.value) : undefined })
        }
      >
        <option value="">Select province</option>
        {provinces?.map((p) => (
          <option key={p.id} value={p.id}>{p.name}</option>
        ))}
      </Select>

      <Select
        label="District"
        value={value.district_id ?? ''}
        error={errors?.district_id}
        disabled={!value.province_id || districtsPending}
        onChange={(e) =>
          onChange({ ...value, district_id: e.target.value ? Number(e.target.value) : undefined, municipality_id: undefined, ward_id: undefined, neighborhood_id: undefined })
        }
      >
        <option value="">Select district</option>
        {districts?.map((d) => (
          <option key={d.id} value={d.id}>{d.name}</option>
        ))}
      </Select>

      <Select
        label="Municipality"
        value={value.municipality_id ?? ''}
        error={errors?.municipality_id}
        disabled={!value.district_id || municipalitiesPending}
        onChange={(e) =>
          onChange({ ...value, municipality_id: e.target.value ? Number(e.target.value) : undefined, ward_id: undefined, neighborhood_id: undefined })
        }
      >
        <option value="">Select municipality</option>
        {municipalities?.map((m) => (
          <option key={m.id} value={m.id}>{m.name}</option>
        ))}
      </Select>

      <Select
        label="Ward"
        value={value.ward_id ?? ''}
        error={errors?.ward_id}
        disabled={!value.municipality_id || wardsPending}
        onChange={(e) =>
          onChange({ ...value, ward_id: e.target.value ? Number(e.target.value) : undefined, neighborhood_id: undefined })
        }
      >
        <option value="">Select ward</option>
        {wards?.map((w) => (
          <option key={w.id} value={w.id}>Ward {w.ward_number}</option>
        ))}
      </Select>

      <Select
        label="Neighborhood (optional)"
        value={value.neighborhood_id ?? ''}
        disabled={!value.ward_id || !neighborhoods?.length}
        onChange={(e) =>
          onChange({ ...value, neighborhood_id: e.target.value ? Number(e.target.value) : undefined })
        }
      >
        <option value="">{neighborhoods?.length ? 'Select neighborhood' : 'None listed yet'}</option>
        {neighborhoods?.map((n) => (
          <option key={n.id} value={n.id}>{n.name}</option>
        ))}
      </Select>
    </div>
  )
}
