import { useState } from 'react'
import { MapPin, Trash2 } from 'lucide-react'
import {
  useDistricts,
  useMunicipalities,
  useNeighborhoods,
  useProvinces,
  useWards,
} from '../../lib/api/locations'
import {
  useCreateDistrict,
  useCreateMunicipality,
  useCreateNeighborhood,
  useCreateProvince,
  useCreateWard,
  useDeleteDistrict,
  useDeleteMunicipality,
  useDeleteNeighborhood,
  useDeleteProvince,
  useDeleteWard,
  useUpdateMunicipality,
} from '../../lib/api/adminLocations'
import { AdminPageHeader } from '../../components/admin/AdminPageHeader'
import { Card } from '../../components/ui/Card'
import { Input, Select } from '../../components/ui/Input'
import { Button } from '../../components/ui/Button'
import { Tabs } from '../../components/ui/Tabs'
import { getErrorMessage } from '../../lib/api/errors'

export function Locations() {
  const [tab, setTab] = useState('provinces')

  return (
    <div className="flex flex-col gap-4">
      <AdminPageHeader
        icon={MapPin}
        tone="trust"
        title="Locations"
        description="Nepal's admin hierarchy — province, district, municipality, ward, neighborhood."
      />
      <Tabs
        tabs={[
          { key: 'provinces', label: 'Provinces' },
          { key: 'districts', label: 'Districts' },
          { key: 'municipalities', label: 'Municipalities' },
          { key: 'wards', label: 'Wards' },
          { key: 'neighborhoods', label: 'Neighborhoods' },
        ]}
        active={tab}
        onChange={setTab}
      />
      {tab === 'provinces' && <ProvincesTab />}
      {tab === 'districts' && <DistrictsTab />}
      {tab === 'municipalities' && <MunicipalitiesTab />}
      {tab === 'wards' && <WardsTab />}
      {tab === 'neighborhoods' && <NeighborhoodsTab />}
    </div>
  )
}

function Row({ label, sub, onDelete }: { label: string; sub?: string; onDelete: () => void }) {
  return (
    <div className="flex items-center justify-between gap-2 border-b border-stone-100 py-2 last:border-0">
      <div>
        <p className="text-sm font-medium text-ink-900">{label}</p>
        {sub && <p className="text-xs text-ink-700/60">{sub}</p>}
      </div>
      <button type="button" onClick={onDelete} aria-label="Delete" className="rounded-md p-1.5 text-ink-700/50 hover:bg-stone-100 hover:text-danger-600">
        <Trash2 className="h-4 w-4" />
      </button>
    </div>
  )
}

function ProvincesTab() {
  const { data: provinces } = useProvinces()
  const create = useCreateProvince()
  const remove = useDeleteProvince()
  const [form, setForm] = useState({ name: '', code: '' })
  const [error, setError] = useState<string | null>(null)

  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
      <Card className="p-4">
        <h3 className="mb-3 font-medium text-ink-900">Existing provinces</h3>
        {provinces?.map((p) => (
          <Row key={p.id} label={p.name} sub={p.code} onDelete={() => remove.mutate(p.id)} />
        ))}
      </Card>
      <Card className="flex flex-col gap-3 p-4">
        <h3 className="font-medium text-ink-900">Add province</h3>
        <Input label="Name" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
        <Input label="Code" value={form.code} onChange={(e) => setForm({ ...form, code: e.target.value })} />
        {error && <p className="text-sm text-danger-600">{error}</p>}
        <Button
          isLoading={create.isPending}
          disabled={!form.name || !form.code}
          onClick={() =>
            create.mutate(form, {
              onSuccess: () => { setForm({ name: '', code: '' }); setError(null) },
              onError: (e) => setError(getErrorMessage(e)),
            })
          }
        >
          Add
        </Button>
      </Card>
    </div>
  )
}

function DistrictsTab() {
  const { data: provinces } = useProvinces()
  const [provinceId, setProvinceId] = useState<number>()
  const { data: districts } = useDistricts(provinceId)
  const create = useCreateDistrict()
  const remove = useDeleteDistrict()
  const [form, setForm] = useState({ name: '', code: '' })
  const [error, setError] = useState<string | null>(null)

  return (
    <div className="flex flex-col gap-4">
      <Select label="Province" value={provinceId ?? ''} onChange={(e) => setProvinceId(e.target.value ? Number(e.target.value) : undefined)}>
        <option value="">Select a province</option>
        {provinces?.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
      </Select>

      {provinceId && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <Card className="p-4">
            <h3 className="mb-3 font-medium text-ink-900">Districts</h3>
            {districts?.map((d) => (
              <Row key={d.id} label={d.name} sub={d.code} onDelete={() => remove.mutate(d.id)} />
            ))}
            {districts?.length === 0 && <p className="text-sm text-ink-700/60">No districts yet.</p>}
          </Card>
          <Card className="flex flex-col gap-3 p-4">
            <h3 className="font-medium text-ink-900">Add district</h3>
            <Input label="Name" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
            <Input label="Code" value={form.code} onChange={(e) => setForm({ ...form, code: e.target.value })} />
            {error && <p className="text-sm text-danger-600">{error}</p>}
            <Button
              isLoading={create.isPending}
              disabled={!form.name || !form.code}
              onClick={() =>
                create.mutate(
                  { ...form, province_id: provinceId },
                  { onSuccess: () => { setForm({ name: '', code: '' }); setError(null) }, onError: (e) => setError(getErrorMessage(e)) },
                )
              }
            >
              Add
            </Button>
          </Card>
        </div>
      )}
    </div>
  )
}

function MunicipalitiesTab() {
  const { data: provinces } = useProvinces()
  const [provinceId, setProvinceId] = useState<number>()
  const { data: districts } = useDistricts(provinceId)
  const [districtId, setDistrictId] = useState<number>()
  const { data: municipalities } = useMunicipalities(districtId)
  const create = useCreateMunicipality()
  const update = useUpdateMunicipality()
  const remove = useDeleteMunicipality()
  const [form, setForm] = useState({ name: '', code: '', type: 'municipality', ward_count: '10' })
  const [image, setImage] = useState<File | null>(null)
  const [error, setError] = useState<string | null>(null)

  return (
    <div className="flex flex-col gap-4">
      <div className="grid grid-cols-2 gap-4">
        <Select label="Province" value={provinceId ?? ''} onChange={(e) => { setProvinceId(e.target.value ? Number(e.target.value) : undefined); setDistrictId(undefined) }}>
          <option value="">Select a province</option>
          {provinces?.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
        </Select>
        <Select label="District" value={districtId ?? ''} disabled={!provinceId} onChange={(e) => setDistrictId(e.target.value ? Number(e.target.value) : undefined)}>
          <option value="">Select a district</option>
          {districts?.map((d) => <option key={d.id} value={d.id}>{d.name}</option>)}
        </Select>
      </div>

      {districtId && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <Card className="p-4">
            <h3 className="mb-3 font-medium text-ink-900">Municipalities</h3>
            {municipalities?.map((m) => (
              <div key={m.id} className="flex items-center justify-between gap-2 border-b border-stone-100 py-2 last:border-0">
                <div className="flex min-w-0 items-center gap-2.5">
                  {m.image_url ? (
                    <img src={m.image_url} alt="" className="h-10 w-14 shrink-0 rounded-md object-cover" />
                  ) : (
                    <span className="flex h-10 w-14 shrink-0 items-center justify-center rounded-md bg-stone-100 text-ink-700/30">
                      <MapPin className="h-4 w-4" />
                    </span>
                  )}
                  <div className="min-w-0">
                    <p className="truncate text-sm font-medium text-ink-900">{m.name}</p>
                    <p className="text-xs text-ink-700/60">{m.type.replace('_', ' ')} · {m.ward_count} wards</p>
                  </div>
                </div>
                <div className="flex shrink-0 items-center gap-1">
                  <label className="cursor-pointer rounded-md px-2 py-1.5 text-xs font-medium text-trust-700 hover:bg-trust-100">
                    {m.image_url ? 'Replace photo' : 'Add photo'}
                    <input
                      type="file"
                      accept="image/jpeg,image/png,image/webp"
                      className="hidden"
                      onChange={(e) => {
                        const file = e.target.files?.[0]
                        if (file) update.mutate({ id: m.id, image: file })
                        e.target.value = ''
                      }}
                    />
                  </label>
                  <button type="button" onClick={() => remove.mutate(m.id)} aria-label="Delete" className="rounded-md p-1.5 text-ink-700/50 hover:bg-stone-100 hover:text-danger-600">
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </div>
            ))}
            {municipalities?.length === 0 && <p className="text-sm text-ink-700/60">No municipalities yet.</p>}
          </Card>
          <Card className="flex flex-col gap-3 p-4">
            <h3 className="font-medium text-ink-900">Add municipality</h3>
            <Input label="Name" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
            <Select label="Type" value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value })}>
              <option value="metropolitan">Metropolitan city</option>
              <option value="sub_metropolitan">Sub-metropolitan city</option>
              <option value="municipality">Municipality</option>
              <option value="rural_municipality">Rural municipality</option>
            </Select>
            <Input label="Code" placeholder="e.g. M-KTM" value={form.code} onChange={(e) => setForm({ ...form, code: e.target.value })} />
            <Input
              label="Number of wards"
              type="number"
              min="1"
              placeholder="e.g. 32"
              value={form.ward_count}
              onChange={(e) => setForm({ ...form, ward_count: e.target.value })}
            />
            <label className="flex flex-col gap-1.5 text-sm font-medium text-ink-900">
              Photo (optional — shown on the homepage "Browse by city" tile)
              <input
                type="file"
                accept="image/jpeg,image/png,image/webp"
                onChange={(e) => setImage(e.target.files?.[0] ?? null)}
                className="rounded-lg border border-stone-200 px-3 py-2 text-sm"
              />
            </label>
            {error && <p className="text-sm text-danger-600">{error}</p>}
            <Button
              isLoading={create.isPending}
              disabled={!form.name || !form.code}
              onClick={() =>
                create.mutate(
                  { ...form, district_id: districtId, ward_count: Number(form.ward_count), image: image ?? undefined },
                  {
                    onSuccess: () => { setForm({ name: '', code: '', type: 'municipality', ward_count: '10' }); setImage(null); setError(null) },
                    onError: (e) => setError(getErrorMessage(e)),
                  },
                )
              }
            >
              Add (creates its wards automatically)
            </Button>
          </Card>
        </div>
      )}
    </div>
  )
}

function WardsTab() {
  const { data: provinces } = useProvinces()
  const [provinceId, setProvinceId] = useState<number>()
  const { data: districts } = useDistricts(provinceId)
  const [districtId, setDistrictId] = useState<number>()
  const { data: municipalities } = useMunicipalities(districtId)
  const [municipalityId, setMunicipalityId] = useState<number>()
  const { data: wards } = useWards(municipalityId)
  const create = useCreateWard()
  const remove = useDeleteWard()
  const [form, setForm] = useState({ ward_number: '', name: '' })
  const [error, setError] = useState<string | null>(null)

  return (
    <div className="flex flex-col gap-4">
      <div className="grid grid-cols-3 gap-4">
        <Select label="Province" value={provinceId ?? ''} onChange={(e) => { setProvinceId(e.target.value ? Number(e.target.value) : undefined); setDistrictId(undefined); setMunicipalityId(undefined) }}>
          <option value="">Select</option>
          {provinces?.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
        </Select>
        <Select label="District" value={districtId ?? ''} disabled={!provinceId} onChange={(e) => { setDistrictId(e.target.value ? Number(e.target.value) : undefined); setMunicipalityId(undefined) }}>
          <option value="">Select</option>
          {districts?.map((d) => <option key={d.id} value={d.id}>{d.name}</option>)}
        </Select>
        <Select label="Municipality" value={municipalityId ?? ''} disabled={!districtId} onChange={(e) => setMunicipalityId(e.target.value ? Number(e.target.value) : undefined)}>
          <option value="">Select</option>
          {municipalities?.map((m) => <option key={m.id} value={m.id}>{m.name}</option>)}
        </Select>
      </div>

      {municipalityId && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <Card className="p-4">
            <h3 className="mb-3 font-medium text-ink-900">Wards</h3>
            <div className="max-h-80 overflow-y-auto">
              {wards?.map((w) => (
                <Row key={w.id} label={`Ward ${w.ward_number}`} sub={w.name ?? undefined} onDelete={() => remove.mutate(w.id)} />
              ))}
            </div>
          </Card>
          <Card className="flex flex-col gap-3 p-4">
            <h3 className="font-medium text-ink-900">Add ward</h3>
            <Input label="Ward number" type="number" min="1" placeholder="e.g. 5" value={form.ward_number} onChange={(e) => setForm({ ...form, ward_number: e.target.value })} />
            <Input label="Name (optional)" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
            {error && <p className="text-sm text-danger-600">{error}</p>}
            <Button
              isLoading={create.isPending}
              disabled={!form.ward_number}
              onClick={() =>
                create.mutate(
                  { municipality_id: municipalityId, ward_number: Number(form.ward_number), name: form.name || undefined },
                  { onSuccess: () => { setForm({ ward_number: '', name: '' }); setError(null) }, onError: (e) => setError(getErrorMessage(e)) },
                )
              }
            >
              Add
            </Button>
          </Card>
        </div>
      )}
    </div>
  )
}

function NeighborhoodsTab() {
  const { data: provinces } = useProvinces()
  const [provinceId, setProvinceId] = useState<number>()
  const { data: districts } = useDistricts(provinceId)
  const [districtId, setDistrictId] = useState<number>()
  const { data: municipalities } = useMunicipalities(districtId)
  const [municipalityId, setMunicipalityId] = useState<number>()
  const { data: wards } = useWards(municipalityId)
  const [wardId, setWardId] = useState<number>()
  const { data: neighborhoods } = useNeighborhoods(wardId)
  const create = useCreateNeighborhood()
  const remove = useDeleteNeighborhood()
  const [form, setForm] = useState({ name: '' })
  const [error, setError] = useState<string | null>(null)

  return (
    <div className="flex flex-col gap-4">
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        <Select label="Province" value={provinceId ?? ''} onChange={(e) => { setProvinceId(e.target.value ? Number(e.target.value) : undefined); setDistrictId(undefined); setMunicipalityId(undefined); setWardId(undefined) }}>
          <option value="">Select</option>
          {provinces?.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
        </Select>
        <Select label="District" value={districtId ?? ''} disabled={!provinceId} onChange={(e) => { setDistrictId(e.target.value ? Number(e.target.value) : undefined); setMunicipalityId(undefined); setWardId(undefined) }}>
          <option value="">Select</option>
          {districts?.map((d) => <option key={d.id} value={d.id}>{d.name}</option>)}
        </Select>
        <Select label="Municipality" value={municipalityId ?? ''} disabled={!districtId} onChange={(e) => { setMunicipalityId(e.target.value ? Number(e.target.value) : undefined); setWardId(undefined) }}>
          <option value="">Select</option>
          {municipalities?.map((m) => <option key={m.id} value={m.id}>{m.name}</option>)}
        </Select>
        <Select label="Ward" value={wardId ?? ''} disabled={!municipalityId} onChange={(e) => setWardId(e.target.value ? Number(e.target.value) : undefined)}>
          <option value="">Select</option>
          {wards?.map((w) => <option key={w.id} value={w.id}>Ward {w.ward_number}</option>)}
        </Select>
      </div>

      {wardId && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <Card className="p-4">
            <h3 className="mb-3 font-medium text-ink-900">Neighborhoods</h3>
            {neighborhoods?.map((n) => (
              <Row key={n.id} label={n.name} onDelete={() => remove.mutate(n.id)} />
            ))}
            {neighborhoods?.length === 0 && <p className="text-sm text-ink-700/60">None listed yet.</p>}
          </Card>
          <Card className="flex flex-col gap-3 p-4">
            <h3 className="font-medium text-ink-900">Add neighborhood</h3>
            <Input label="Name" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
            {error && <p className="text-sm text-danger-600">{error}</p>}
            <Button
              isLoading={create.isPending}
              disabled={!form.name}
              onClick={() =>
                create.mutate(
                  { ward_id: wardId, name: form.name },
                  { onSuccess: () => { setForm({ name: '' }); setError(null) }, onError: (e) => setError(getErrorMessage(e)) },
                )
              }
            >
              Add
            </Button>
          </Card>
        </div>
      )}
    </div>
  )
}
