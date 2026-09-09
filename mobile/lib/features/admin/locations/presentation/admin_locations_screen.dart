import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/error_state.dart';
import '../../../../widgets/skeleton.dart';
import '../application/admin_locations_providers.dart';
import '../data/admin_locations_repository.dart';
import '../data/models/district.dart';
import '../data/models/municipality.dart';
import '../data/models/neighborhood.dart';
import '../data/models/province.dart';
import '../data/models/ward.dart';

String _municipalityTypeLabel(String type) =>
    type.split('_').map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> _confirmDelete(BuildContext context, String label) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete?'),
      content: Text('Delete $label? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Compact inline error treatment for the secondary scoping dropdowns
/// embedded in each tab — the full-weight [ErrorState] would be too heavy
/// here, but a retry action is still required.
class _InlineLoadError extends StatelessWidget {
  const _InlineLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.danger600),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Tabbed Province/District/Municipality/Ward/Neighborhood CRUD, mirroring
/// the website's admin location manager. Each level below Province is
/// scoped by a cascading parent selector — Municipality is the one
/// exception that loads unfiltered when no district is chosen yet.
class AdminLocationsScreen extends ConsumerStatefulWidget {
  const AdminLocationsScreen({super.key});

  @override
  ConsumerState<AdminLocationsScreen> createState() => _AdminLocationsScreenState();
}

class _AdminLocationsScreenState extends ConsumerState<AdminLocationsScreen> {
  int? _provinceId;
  int? _districtId;
  int? _municipalityId;

  void _setProvince(int? id) {
    setState(() {
      _provinceId = id;
      _districtId = null;
      _municipalityId = null;
    });
  }

  void _setDistrict(int? id) {
    setState(() {
      _districtId = id;
      _municipalityId = null;
    });
  }

  void _setMunicipality(int? id) {
    setState(() => _municipalityId = id);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Locations'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Provinces'),
              Tab(text: 'Districts'),
              Tab(text: 'Municipalities'),
              Tab(text: 'Wards'),
              Tab(text: 'Neighborhoods'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ProvincesTab(selectedId: _provinceId, onSelect: _setProvince),
            _DistrictsTab(provinceId: _provinceId, onSelectProvince: _setProvince, selectedId: _districtId, onSelect: _setDistrict),
            _MunicipalitiesTab(
              districtId: _districtId,
              onSelectDistrict: _setDistrict,
              selectedId: _municipalityId,
              onSelect: _setMunicipality,
            ),
            _WardsTab(municipalityId: _municipalityId, onSelectMunicipality: _setMunicipality),
            _NeighborhoodsTab(municipalityId: _municipalityId, onSelectMunicipality: _setMunicipality),
          ],
        ),
      ),
    );
  }
}

// ============================== Provinces ==============================

class _ProvincesTab extends ConsumerWidget {
  const _ProvincesTab({required this.selectedId, required this.onSelect});

  final int? selectedId;
  final ValueChanged<int?> onSelect;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<(String, String?, String)>(
      context: context,
      builder: (context) => const _ProvinceFormDialog(),
    );
    if (result == null) return;
    try {
      await ref
          .read(adminLocationsRepositoryProvider)
          .createProvince(name: result.$1, nameNe: result.$2, code: result.$3);
      ref.invalidate(adminProvincesProvider);
      if (context.mounted) _showMessage(context, 'Province created.');
    } catch (error) {
      if (context.mounted) _showMessage(context, friendlyDeleteErrorMessage(error));
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Province province) async {
    final result = await showDialog<(String, String?, String)>(
      context: context,
      builder: (context) => _ProvinceFormDialog(province: province),
    );
    if (result == null) return;
    try {
      await ref
          .read(adminLocationsRepositoryProvider)
          .updateProvince(province.id, name: result.$1, nameNe: result.$2, code: result.$3);
      ref.invalidate(adminProvincesProvider);
      if (context.mounted) _showMessage(context, 'Province updated.');
    } catch (error) {
      if (context.mounted) _showMessage(context, friendlyDeleteErrorMessage(error));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Province province) async {
    if (!await _confirmDelete(context, province.name)) return;
    try {
      await ref.read(adminLocationsRepositoryProvider).deleteProvince(province.id);
      ref.invalidate(adminProvincesProvider);
      if (province.id == selectedId) onSelect(null);
      if (context.mounted) _showMessage(context, 'Province deleted.');
    } catch (error) {
      if (context.mounted) _showMessage(context, friendlyDeleteErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provinces = ref.watch(adminProvincesProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(label: 'Add province', expand: false, onPressed: () => _add(context, ref)),
          const SizedBox(height: 12),
          Expanded(
            child: provinces.when(
              loading: () => const Skeleton(height: 400),
              error: (error, _) =>
                  ErrorState(message: 'Could not load provinces.', onRetry: () => ref.invalidate(adminProvincesProvider)),
              data: (items) => items.isEmpty
                  ? const EmptyState(title: 'No provinces yet.', icon: Icons.map_outlined)
                  : ListView(
                      children: [
                        for (final p in items)
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: p.id == selectedId ? AppColors.trust100 : null,
                            child: ListTile(
                              title: Text(p.name),
                              subtitle: Text('${p.code}${p.nameNe != null ? ' · ${p.nameNe}' : ''}'),
                              onTap: () => onSelect(p.id),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: 'Edit ${p.name}',
                                    onPressed: () => _edit(context, ref, p),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: 'Delete ${p.name}',
                                    onPressed: () => _delete(context, ref, p),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProvinceFormDialog extends StatefulWidget {
  const _ProvinceFormDialog({this.province});

  final Province? province;

  @override
  State<_ProvinceFormDialog> createState() => _ProvinceFormDialogState();
}

class _ProvinceFormDialogState extends State<_ProvinceFormDialog> {
  late final _name = TextEditingController(text: widget.province?.name);
  late final _nameNe = TextEditingController(text: widget.province?.nameNe);
  late final _code = TextEditingController(text: widget.province?.code);

  @override
  void dispose() {
    _name.dispose();
    _nameNe.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.province == null ? 'Add province' : 'Edit province'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: _nameNe, decoration: const InputDecoration(labelText: 'Name (Nepali)')),
          TextField(controller: _code, decoration: const InputDecoration(labelText: 'Code')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            if (_name.text.trim().isEmpty || _code.text.trim().isEmpty) return;
            Navigator.of(context).pop((
              _name.text.trim(),
              _nameNe.text.trim().isEmpty ? null : _nameNe.text.trim(),
              _code.text.trim(),
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ============================== Districts ==============================

class _DistrictsTab extends ConsumerWidget {
  const _DistrictsTab({
    required this.provinceId,
    required this.onSelectProvince,
    required this.selectedId,
    required this.onSelect,
  });

  final int? provinceId;
  final ValueChanged<int?> onSelectProvince;
  final int? selectedId;
  final ValueChanged<int?> onSelect;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final pid = provinceId;
    if (pid == null) return;
    final result = await showDialog<(String, String?, String)>(
      context: context,
      builder: (context) => const _NameCodeFormDialog(title: 'Add district'),
    );
    if (result == null) return;
    try {
      await ref
          .read(adminLocationsRepositoryProvider)
          .createDistrict(provinceId: pid, name: result.$1, nameNe: result.$2, code: result.$3);
      ref.invalidate(adminDistrictsProvider(pid));
      if (context.mounted) _showMessage(context, 'District created.');
    } catch (error) {
      if (context.mounted) _showMessage(context, friendlyDeleteErrorMessage(error));
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, District district) async {
    final result = await showDialog<(String, String?, String)>(
      context: context,
      builder: (context) => _NameCodeFormDialog(
        title: 'Edit district',
        initialName: district.name,
        initialNameNe: district.nameNe,
        initialCode: district.code,
      ),
    );
    if (result == null) return;
    try {
      await ref
          .read(adminLocationsRepositoryProvider)
          .updateDistrict(district.id, name: result.$1, nameNe: result.$2, code: result.$3);
      ref.invalidate(adminDistrictsProvider(district.provinceId));
      if (context.mounted) _showMessage(context, 'District updated.');
    } catch (error) {
      if (context.mounted) _showMessage(context, friendlyDeleteErrorMessage(error));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, District district) async {
    if (!await _confirmDelete(context, district.name)) return;
    try {
      await ref.read(adminLocationsRepositoryProvider).deleteDistrict(district.id);
      ref.invalidate(adminDistrictsProvider(district.provinceId));
      if (district.id == selectedId) onSelect(null);
      if (context.mounted) _showMessage(context, 'District deleted.');
    } catch (error) {
      if (context.mounted) _showMessage(context, friendlyDeleteErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provinces = ref.watch(adminProvincesProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          provinces.when(
            loading: () => const Skeleton(height: 56),
            error: (_, _) => _InlineLoadError(
              message: 'Could not load provinces.',
              onRetry: () => ref.invalidate(adminProvincesProvider),
            ),
            data: (items) => DropdownButtonFormField<int>(
              initialValue: provinceId,
              decoration: const InputDecoration(labelText: 'Province'),
              items: [for (final p in items) DropdownMenuItem(value: p.id, child: Text(p.name))],
              onChanged: onSelectProvince,
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Add district',
            expand: false,
            onPressed: provinceId == null ? null : () => _add(context, ref),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: provinceId == null
                ? const EmptyState(title: 'Select a province to view its districts.', icon: Icons.map_outlined)
                : Consumer(
                    builder: (context, ref, _) {
                      final districts = ref.watch(adminDistrictsProvider(provinceId));
                      return districts.when(
                        loading: () => const Skeleton(height: 400),
                        error: (error, _) => ErrorState(
                          message: 'Could not load districts.',
                          onRetry: () => ref.invalidate(adminDistrictsProvider(provinceId)),
                        ),
                        data: (items) => items.isEmpty
                            ? const EmptyState(title: 'No districts yet.', icon: Icons.map_outlined)
                            : ListView(
                                children: [
                                  for (final d in items)
                                    Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      color: d.id == selectedId ? AppColors.trust100 : null,
                                      child: ListTile(
                                        title: Text(d.name),
                                        subtitle: Text('${d.code}${d.nameNe != null ? ' · ${d.nameNe}' : ''}'),
                                        onTap: () => onSelect(d.id),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined),
                                              tooltip: 'Edit ${d.name}',
                                              onPressed: () => _edit(context, ref, d),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline),
                                              tooltip: 'Delete ${d.name}',
                                              onPressed: () => _delete(context, ref, d),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Reusable name/name_ne/code dialog for District (and re-shaped for other
/// simple entities). Returns `(name, nameNe, code)` or null if cancelled.
class _NameCodeFormDialog extends StatefulWidget {
  const _NameCodeFormDialog({required this.title, this.initialName, this.initialNameNe, this.initialCode});

  final String title;
  final String? initialName;
  final String? initialNameNe;
  final String? initialCode;

  @override
  State<_NameCodeFormDialog> createState() => _NameCodeFormDialogState();
}

class _NameCodeFormDialogState extends State<_NameCodeFormDialog> {
  late final _name = TextEditingController(text: widget.initialName);
  late final _nameNe = TextEditingController(text: widget.initialNameNe);
  late final _code = TextEditingController(text: widget.initialCode);

  @override
  void dispose() {
    _name.dispose();
    _nameNe.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: _nameNe, decoration: const InputDecoration(labelText: 'Name (Nepali)')),
          TextField(controller: _code, decoration: const InputDecoration(labelText: 'Code')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            if (_name.text.trim().isEmpty || _code.text.trim().isEmpty) return;
            Navigator.of(context).pop((
              _name.text.trim(),
              _nameNe.text.trim().isEmpty ? null : _nameNe.text.trim(),
              _code.text.trim(),
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ============================== Municipalities ==============================

class _MunicipalitiesTab extends ConsumerWidget {
  const _MunicipalitiesTab({
    required this.districtId,
    required this.onSelectDistrict,
    required this.selectedId,
    required this.onSelect,
  });

  final int? districtId;
  final ValueChanged<int?> onSelectDistrict;
  final int? selectedId;
  final ValueChanged<int?> onSelect;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_MunicipalityFormResult>(
      context: context,
      builder: (context) => _MunicipalityFormDialog(initialDistrictId: districtId),
    );
    if (result == null) return;
    try {
      await ref
          .read(adminLocationsRepositoryProvider)
          .createMunicipality(
            districtId: result.districtId,
            name: result.name,
            nameNe: result.nameNe,
            type: result.type,
            code: result.code,
            wardCount: result.wardCount!,
            imagePath: result.imagePath,
          );
      ref.invalidate(adminMunicipalitiesProvider(districtId));
      if (context.mounted) {
        _showMessage(context, 'Municipality created with ${result.wardCount} ward(s) auto-provisioned.');
      }
    } catch (error) {
      if (context.mounted) _showMessage(context, friendlyDeleteErrorMessage(error));
    }
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Municipality municipality) async {
    final result = await showDialog<_MunicipalityFormResult>(
      context: context,
      builder: (context) => _MunicipalityFormDialog(municipality: municipality),
    );
    if (result == null) return;
    try {
      await ref
          .read(adminLocationsRepositoryProvider)
          .updateMunicipality(
            municipality.id,
            districtId: result.districtId,
            name: result.name,
            nameNe: result.nameNe,
            type: result.type,
            code: result.code,
            imagePath: result.imagePath,
          );
      ref.invalidate(adminMunicipalitiesProvider(districtId));
      if (context.mounted) _showMessage(context, 'Municipality updated.');
    } catch (error) {
      if (context.mounted) _showMessage(context, friendlyDeleteErrorMessage(error));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Municipality municipality) async {
    if (!await _confirmDelete(context, municipality.name)) return;
    try {
      await ref.read(adminLocationsRepositoryProvider).deleteMunicipality(municipality.id);
      ref.invalidate(adminMunicipalitiesProvider(districtId));
      if (municipality.id == selectedId) onSelect(null);
      if (context.mounted) _showMessage(context, 'Municipality deleted.');
    } catch (error) {
      if (context.mounted) _showMessage(context, friendlyDeleteErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final municipalities = ref.watch(adminMunicipalitiesProvider(districtId));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AnyDistrictDropdown(selectedId: districtId, onChanged: onSelectDistrict),
          const SizedBox(height: 12),
          AppButton(label: 'Add municipality', expand: false, onPressed: () => _add(context, ref)),
          const SizedBox(height: 4),
          const Text(
            'Creating a municipality auto-provisions its wards (1..N) — no need to add them separately.',
            style: TextStyle(color: AppColors.ink700, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: municipalities.when(
              loading: () => const Skeleton(height: 400),
              error: (error, _) => ErrorState(
                message: 'Could not load municipalities.',
                onRetry: () => ref.invalidate(adminMunicipalitiesProvider(districtId)),
              ),
              data: (items) => items.isEmpty
                  ? const EmptyState(title: 'No municipalities yet.', icon: Icons.location_city_outlined)
                  : ListView(
                      children: [
                        for (final m in items)
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: m.id == selectedId ? AppColors.trust100 : null,
                            child: ListTile(
                              leading: m.imageUrl != null
                                  ? CircleAvatar(backgroundImage: NetworkImage(m.imageUrl!))
                                  : const CircleAvatar(child: Icon(Icons.location_city_outlined)),
                              title: Text(m.name),
                              subtitle: Text('${_municipalityTypeLabel(m.type)} · ${m.wardCount} wards · ${m.code}'),
                              onTap: () => onSelect(m.id),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: 'Edit ${m.name}',
                                    onPressed: () => _edit(context, ref, m),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: 'Delete ${m.name}',
                                    onPressed: () => _delete(context, ref, m),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A district dropdown across ALL provinces (used to pick a scoping district
/// for Municipalities, where "no selection" is a valid, meaningful state —
/// unlike the Districts tab, which requires a province first).
class _AnyDistrictDropdown extends ConsumerWidget {
  const _AnyDistrictDropdown({required this.selectedId, required this.onChanged});

  final int? selectedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provinces = ref.watch(adminProvincesProvider);

    return provinces.when(
      loading: () => const Skeleton(height: 56),
      error: (_, _) => _InlineLoadError(
        message: 'Could not load districts.',
        onRetry: () => ref.invalidate(adminProvincesProvider),
      ),
      data: (provinceList) => _AllDistrictsDropdown(
        provinces: provinceList,
        selectedId: selectedId,
        onChanged: onChanged,
      ),
    );
  }
}

class _AllDistrictsDropdown extends ConsumerWidget {
  const _AllDistrictsDropdown({required this.provinces, required this.selectedId, required this.onChanged});

  final List<Province> provinces;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Flatten every province's districts into one list for a single dropdown.
    final asyncLists = [for (final p in provinces) ref.watch(adminDistrictsProvider(p.id))];
    final loaded = asyncLists.every((a) => a.hasValue);
    if (!loaded) return const Skeleton(height: 56);

    final allDistricts = <District>[for (final a in asyncLists) ...a.value!];
    return DropdownButtonFormField<int?>(
      initialValue: selectedId,
      decoration: const InputDecoration(labelText: 'District (optional — leave blank to show all municipalities)'),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('All districts')),
        for (final d in allDistricts) DropdownMenuItem<int?>(value: d.id, child: Text(d.name)),
      ],
      onChanged: onChanged,
    );
  }
}

class _MunicipalityFormResult {
  _MunicipalityFormResult({
    required this.districtId,
    required this.name,
    this.nameNe,
    required this.type,
    required this.code,
    this.wardCount,
    this.imagePath,
  });

  final int districtId;
  final String name;
  final String? nameNe;
  final String type;
  final String code;
  final int? wardCount;
  final String? imagePath;
}

class _MunicipalityFormDialog extends ConsumerStatefulWidget {
  const _MunicipalityFormDialog({this.municipality, this.initialDistrictId});

  final Municipality? municipality;
  final int? initialDistrictId;

  @override
  ConsumerState<_MunicipalityFormDialog> createState() => _MunicipalityFormDialogState();
}

class _MunicipalityFormDialogState extends ConsumerState<_MunicipalityFormDialog> {
  late final _name = TextEditingController(text: widget.municipality?.name);
  late final _nameNe = TextEditingController(text: widget.municipality?.nameNe);
  late final _code = TextEditingController(text: widget.municipality?.code);
  late final _wardCount = TextEditingController(
    text: widget.municipality == null ? '' : widget.municipality!.wardCount.toString(),
  );
  int? _districtId;
  late String _type = widget.municipality?.type ?? kMunicipalityTypes.first;
  String? _imagePath;

  bool get _isEdit => widget.municipality != null;

  @override
  void initState() {
    super.initState();
    _districtId = widget.municipality?.districtId ?? widget.initialDistrictId;
  }

  @override
  void dispose() {
    _name.dispose();
    _nameNe.dispose();
    _code.dispose();
    _wardCount.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _imagePath = picked.path);
  }

  void _submit() {
    final districtId = _districtId;
    if (districtId == null || _name.text.trim().isEmpty || _code.text.trim().isEmpty) return;
    int? wardCount;
    if (!_isEdit) {
      wardCount = int.tryParse(_wardCount.text.trim());
      if (wardCount == null || wardCount < 1 || wardCount > 50) return;
    }
    Navigator.of(context).pop(
      _MunicipalityFormResult(
        districtId: districtId,
        name: _name.text.trim(),
        nameNe: _nameNe.text.trim().isEmpty ? null : _nameNe.text.trim(),
        type: _type,
        code: _code.text.trim(),
        wardCount: wardCount,
        imagePath: _imagePath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provinces = ref.watch(adminProvincesProvider);

    return AlertDialog(
      title: Text(_isEdit ? 'Edit municipality' : 'Add municipality'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            provinces.when(
              loading: () => const Skeleton(height: 56),
              error: (_, _) => _InlineLoadError(
                message: 'Could not load districts.',
                onRetry: () => ref.invalidate(adminProvincesProvider),
              ),
              data: (provinceList) => _AllDistrictsDropdown(
                provinces: provinceList,
                selectedId: _districtId,
                onChanged: (id) => setState(() => _districtId = id),
              ),
            ),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: _nameNe, decoration: const InputDecoration(labelText: 'Name (Nepali)')),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                for (final t in kMunicipalityTypes) DropdownMenuItem(value: t, child: Text(_municipalityTypeLabel(t))),
              ],
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            TextField(controller: _code, decoration: const InputDecoration(labelText: 'Code')),
            if (!_isEdit)
              TextField(
                controller: _wardCount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Ward count (1-50)'),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image_outlined),
              label: Text(_imagePath == null ? 'Choose image (optional)' : 'Image selected'),
            ),
            if (_imagePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(_imagePath!), height: 80, fit: BoxFit.cover),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

// ============================== Wards ==============================

class _WardsTab extends ConsumerWidget {
  const _WardsTab({required this.municipalityId, required this.onSelectMunicipality});

  final int? municipalityId;
  final ValueChanged<int?> onSelectMunicipality;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final mid = municipalityId;
    if (mid == null) return;
    final result = await showDialog<(int, String?)>(
      context: context,
      builder: (context) => const _WardFormDialog(),
    );
    if (result == null) return;
    try {
      await ref
          .read(adminLocationsRepositoryProvider)
          .createWard(municipalityId: mid, wardNumber: result.$1, name: result.$2);
      ref.invalidate(adminWardsProvider(mid));
      if (context.mounted) _showMessage(context, 'Ward created.');
    } catch (error) {
      if (context.mounted) _showMessage(context, friendlyDeleteErrorMessage(error));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Ward ward) async {
    if (!await _confirmDelete(context, 'Ward ${ward.wardNumber}')) return;
    try {
      await ref.read(adminLocationsRepositoryProvider).deleteWard(ward.id);
      ref.invalidate(adminWardsProvider(ward.municipalityId));
      if (context.mounted) _showMessage(context, 'Ward deleted.');
    } catch (error) {
      if (context.mounted) _showMessage(context, friendlyDeleteErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final municipalities = ref.watch(adminMunicipalitiesProvider(null));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          municipalities.when(
            loading: () => const Skeleton(height: 56),
            error: (_, _) => _InlineLoadError(
              message: 'Could not load municipalities.',
              onRetry: () => ref.invalidate(adminMunicipalitiesProvider(null)),
            ),
            data: (items) => DropdownButtonFormField<int>(
              initialValue: municipalityId,
              decoration: const InputDecoration(labelText: 'Municipality'),
              items: [for (final m in items) DropdownMenuItem(value: m.id, child: Text(m.name))],
              onChanged: onSelectMunicipality,
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Add ward',
            expand: false,
            onPressed: municipalityId == null ? null : () => _add(context, ref),
          ),
          const SizedBox(height: 4),
          const Text('Wards can only be added or deleted — there is no edit action.', style: TextStyle(color: AppColors.ink700, fontSize: 12)),
          const SizedBox(height: 8),
          Expanded(
            child: municipalityId == null
                ? const EmptyState(title: 'Select a municipality to view its wards.', icon: Icons.holiday_village_outlined)
                : Consumer(
                    builder: (context, ref, _) {
                      final wards = ref.watch(adminWardsProvider(municipalityId));
                      return wards.when(
                        loading: () => const Skeleton(height: 400),
                        error: (error, _) => ErrorState(
                          message: 'Could not load wards.',
                          onRetry: () => ref.invalidate(adminWardsProvider(municipalityId)),
                        ),
                        data: (items) => items.isEmpty
                            ? const EmptyState(title: 'No wards yet.', icon: Icons.holiday_village_outlined)
                            : ListView(
                                children: [
                                  for (final w in items)
                                    Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        title: Text('Ward ${w.wardNumber}${w.name != null ? ' — ${w.name}' : ''}'),
                                        subtitle: w.centroidLat != null && w.centroidLng != null
                                            ? Text('${w.centroidLat}, ${w.centroidLng}')
                                            : null,
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete_outline),
                                          tooltip: 'Delete Ward ${w.wardNumber}',
                                          onPressed: () => _delete(context, ref, w),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _WardFormDialog extends StatefulWidget {
  const _WardFormDialog();

  @override
  State<_WardFormDialog> createState() => _WardFormDialogState();
}

class _WardFormDialogState extends State<_WardFormDialog> {
  final _wardNumber = TextEditingController();
  final _name = TextEditingController();

  @override
  void dispose() {
    _wardNumber.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add ward'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _wardNumber,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Ward number (1-50)'),
          ),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name (optional)')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final number = int.tryParse(_wardNumber.text.trim());
            if (number == null || number < 1 || number > 50) return;
            Navigator.of(
              context,
            ).pop((number, _name.text.trim().isEmpty ? null : _name.text.trim()));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ============================== Neighborhoods ==============================

class _NeighborhoodsTab extends ConsumerStatefulWidget {
  const _NeighborhoodsTab({required this.municipalityId, required this.onSelectMunicipality});

  final int? municipalityId;
  final ValueChanged<int?> onSelectMunicipality;

  @override
  ConsumerState<_NeighborhoodsTab> createState() => _NeighborhoodsTabState();
}

class _NeighborhoodsTabState extends ConsumerState<_NeighborhoodsTab> {
  int? _wardId;

  Future<void> _add(BuildContext context) async {
    final wid = _wardId;
    if (wid == null) return;
    final result = await showDialog<_NeighborhoodFormResult>(
      context: context,
      builder: (context) => const _NeighborhoodFormDialog(),
    );
    if (result == null) return;
    try {
      await ref
          .read(adminLocationsRepositoryProvider)
          .createNeighborhood(
            wardId: wid,
            name: result.name,
            nameNe: result.nameNe,
            centroidLat: result.centroidLat,
            centroidLng: result.centroidLng,
          );
      ref.invalidate(adminNeighborhoodsProvider(wid));
      if (context.mounted) _showMessage(context, 'Neighborhood created.');
    } catch (error) {
      if (context.mounted) _showMessage(context, friendlyDeleteErrorMessage(error));
    }
  }

  Future<void> _edit(BuildContext context, Neighborhood neighborhood) async {
    final result = await showDialog<_NeighborhoodFormResult>(
      context: context,
      builder: (context) => _NeighborhoodFormDialog(neighborhood: neighborhood),
    );
    if (result == null) return;
    try {
      await ref
          .read(adminLocationsRepositoryProvider)
          .updateNeighborhood(
            neighborhood.id,
            name: result.name,
            nameNe: result.nameNe,
            centroidLat: result.centroidLat,
            centroidLng: result.centroidLng,
            isCurated: result.isCurated,
          );
      ref.invalidate(adminNeighborhoodsProvider(neighborhood.wardId));
      if (context.mounted) _showMessage(context, 'Neighborhood updated.');
    } catch (error) {
      if (context.mounted) _showMessage(context, friendlyDeleteErrorMessage(error));
    }
  }

  Future<void> _delete(BuildContext context, Neighborhood neighborhood) async {
    if (!await _confirmDelete(context, neighborhood.name)) return;
    try {
      await ref.read(adminLocationsRepositoryProvider).deleteNeighborhood(neighborhood.id);
      ref.invalidate(adminNeighborhoodsProvider(neighborhood.wardId));
      if (context.mounted) _showMessage(context, 'Neighborhood deleted.');
    } catch (error) {
      if (context.mounted) _showMessage(context, friendlyDeleteErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final municipalities = ref.watch(adminMunicipalitiesProvider(null));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          municipalities.when(
            loading: () => const Skeleton(height: 56),
            error: (_, _) => _InlineLoadError(
              message: 'Could not load municipalities.',
              onRetry: () => ref.invalidate(adminMunicipalitiesProvider(null)),
            ),
            data: (items) => DropdownButtonFormField<int>(
              initialValue: widget.municipalityId,
              decoration: const InputDecoration(labelText: 'Municipality'),
              items: [for (final m in items) DropdownMenuItem(value: m.id, child: Text(m.name))],
              onChanged: (id) {
                widget.onSelectMunicipality(id);
                setState(() => _wardId = null);
              },
            ),
          ),
          const SizedBox(height: 12),
          if (widget.municipalityId != null)
            Consumer(
              builder: (context, ref, _) {
                final wards = ref.watch(adminWardsProvider(widget.municipalityId));
                return wards.when(
                  loading: () => const Skeleton(height: 56),
                  error: (_, _) => _InlineLoadError(
                    message: 'Could not load wards.',
                    onRetry: () => ref.invalidate(adminWardsProvider(widget.municipalityId)),
                  ),
                  data: (items) => DropdownButtonFormField<int>(
                    initialValue: _wardId,
                    decoration: const InputDecoration(labelText: 'Ward'),
                    items: [for (final w in items) DropdownMenuItem(value: w.id, child: Text('Ward ${w.wardNumber}'))],
                    onChanged: (id) => setState(() => _wardId = id),
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
          AppButton(label: 'Add neighborhood', expand: false, onPressed: _wardId == null ? null : () => _add(context)),
          const SizedBox(height: 8),
          Expanded(
            child: _wardId == null
                ? const EmptyState(title: 'Select a ward to view its neighborhoods.', icon: Icons.holiday_village_outlined)
                : Consumer(
                    builder: (context, ref, _) {
                      final neighborhoods = ref.watch(adminNeighborhoodsProvider(_wardId));
                      return neighborhoods.when(
                        loading: () => const Skeleton(height: 400),
                        error: (error, _) => ErrorState(
                          message: 'Could not load neighborhoods.',
                          onRetry: () => ref.invalidate(adminNeighborhoodsProvider(_wardId)),
                        ),
                        data: (items) => items.isEmpty
                            ? const EmptyState(title: 'No neighborhoods yet.', icon: Icons.holiday_village_outlined)
                            : ListView(
                                children: [
                                  for (final n in items)
                                    Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        title: Text(n.name),
                                        subtitle: Text(n.isCurated ? 'Curated' : 'Not curated'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined),
                                              tooltip: 'Edit ${n.name}',
                                              onPressed: () => _edit(context, n),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline),
                                              tooltip: 'Delete ${n.name}',
                                              onPressed: () => _delete(context, n),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NeighborhoodFormResult {
  _NeighborhoodFormResult({required this.name, this.nameNe, this.centroidLat, this.centroidLng, this.isCurated});

  final String name;
  final String? nameNe;
  final double? centroidLat;
  final double? centroidLng;
  final bool? isCurated;
}

class _NeighborhoodFormDialog extends StatefulWidget {
  const _NeighborhoodFormDialog({this.neighborhood});

  final Neighborhood? neighborhood;

  @override
  State<_NeighborhoodFormDialog> createState() => _NeighborhoodFormDialogState();
}

class _NeighborhoodFormDialogState extends State<_NeighborhoodFormDialog> {
  late final _name = TextEditingController(text: widget.neighborhood?.name);
  late final _nameNe = TextEditingController(text: widget.neighborhood?.nameNe);
  late final _lat = TextEditingController(text: widget.neighborhood?.centroidLat?.toString());
  late final _lng = TextEditingController(text: widget.neighborhood?.centroidLng?.toString());
  late bool _isCurated = widget.neighborhood?.isCurated ?? true;

  bool get _isEdit => widget.neighborhood != null;

  @override
  void dispose() {
    _name.dispose();
    _nameNe.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit neighborhood' : 'Add neighborhood'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: _nameNe, decoration: const InputDecoration(labelText: 'Name (Nepali)')),
            TextField(
              controller: _lat,
              keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
              decoration: const InputDecoration(labelText: 'Centroid latitude (optional)'),
            ),
            TextField(
              controller: _lng,
              keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
              decoration: const InputDecoration(labelText: 'Centroid longitude (optional)'),
            ),
            if (_isEdit)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Curated'),
                value: _isCurated,
                onChanged: (value) => setState(() => _isCurated = value),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            Navigator.of(context).pop(
              _NeighborhoodFormResult(
                name: _name.text.trim(),
                nameNe: _nameNe.text.trim().isEmpty ? null : _nameNe.text.trim(),
                centroidLat: double.tryParse(_lat.text.trim()),
                centroidLng: double.tryParse(_lng.text.trim()),
                isCurated: _isEdit ? _isCurated : null,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
