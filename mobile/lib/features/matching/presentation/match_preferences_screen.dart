import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/error_state.dart';
import '../../locations/application/locations_providers.dart';
import '../application/matching_providers.dart';
import '../data/models/match_preference.dart';
import 'work_location_picker.dart';

/// Mirrors frontend/src/pages/Matching/MatchPreferences.tsx — every field is
/// optional (an unset field simply isn't scored by `MatchScorer`).
class MatchPreferencesScreen extends ConsumerWidget {
  const MatchPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(matchPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Match preferences')),
      body: preferences.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: 'Could not load your preferences.',
          onRetry: () => ref.invalidate(matchPreferencesProvider),
        ),
        data: (data) => _PreferencesForm(initial: data),
      ),
    );
  }
}

const _propertyTypes = ['room', 'apartment', 'house', 'land', 'commercial'];

class _PreferencesForm extends ConsumerStatefulWidget {
  const _PreferencesForm({required this.initial});

  final MatchPreference initial;

  @override
  ConsumerState<_PreferencesForm> createState() => _PreferencesFormState();
}

class _PreferencesFormState extends ConsumerState<_PreferencesForm> {
  late String? _purpose = widget.initial.purpose;
  late String? _propertyType = widget.initial.propertyType;
  late final _budgetMinController = TextEditingController(
    text: widget.initial.budgetMin?.toStringAsFixed(0) ?? '',
  );
  late final _budgetMaxController = TextEditingController(
    text: widget.initial.budgetMax?.toStringAsFixed(0) ?? '',
  );
  late int? _minBedrooms = widget.initial.minBedrooms;
  late int? _municipalityId = widget.initial.preferredMunicipalityId;
  late double? _workLat = widget.initial.workLat;
  late double? _workLng = widget.initial.workLng;
  late final _workLabelController = TextEditingController(text: widget.initial.workLocationLabel ?? '');
  late int? _commuteLimit = widget.initial.commuteLimitMinutes;
  late final _familySizeController = TextEditingController(
    text: widget.initial.familySize?.toString() ?? '',
  );
  late bool _requiresSchool = widget.initial.requiresSchoolNearby ?? false;
  late bool _requiresParking = widget.initial.requiresParking ?? false;
  late bool _investmentPurpose = widget.initial.investmentPurpose ?? false;
  late final Set<String> _lifestyleTags = widget.initial.lifestyleTags.toSet();

  bool _saving = false;

  @override
  void dispose() {
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _workLabelController.dispose();
    _familySizeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(matchingRepositoryProvider)
          .savePreferences(
            purpose: _purpose,
            propertyType: _propertyType,
            budgetMin: double.tryParse(_budgetMinController.text.trim()),
            budgetMax: double.tryParse(_budgetMaxController.text.trim()),
            minBedrooms: _minBedrooms,
            preferredMunicipalityId: _municipalityId,
            workLat: _workLat,
            workLng: _workLng,
            workLocationLabel: _workLabelController.text.trim(),
            commuteLimitMinutes: _commuteLimit,
            familySize: int.tryParse(_familySizeController.text.trim()),
            requiresSchoolNearby: _requiresSchool,
            requiresParking: _requiresParking,
            investmentPurpose: _investmentPurpose,
            lifestyleTags: _lifestyleTags.toList(),
          );
      ref.invalidate(matchPreferencesProvider);
      ref.invalidate(matchResultsProvider);
      if (mounted) context.go('/match-results');
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final municipalities = ref.watch(municipalitiesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Purpose', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<String?>(
          segments: const [
            ButtonSegment(value: null, label: Text('Any')),
            ButtonSegment(value: 'sale', label: Text('Buy')),
            ButtonSegment(value: 'rent', label: Text('Rent')),
          ],
          selected: {_purpose},
          onSelectionChanged: (value) => setState(() => _purpose = value.first),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String?>(
          initialValue: _propertyType,
          decoration: const InputDecoration(labelText: 'Property type'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Any type')),
            ..._propertyTypes.map((t) => DropdownMenuItem(value: t, child: Text(t[0].toUpperCase() + t.substring(1)))),
          ],
          onChanged: (value) => setState(() => _propertyType = value),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _budgetMinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Min budget (Rs)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _budgetMaxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max budget (Rs)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int?>(
          initialValue: _minBedrooms,
          decoration: const InputDecoration(labelText: 'Minimum bedrooms'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Any')),
            ...List.generate(5, (i) => i + 1).map((n) => DropdownMenuItem(value: n, child: Text('$n+'))),
          ],
          onChanged: (value) => setState(() => _minBedrooms = value),
        ),
        const SizedBox(height: 16),
        municipalities.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 18, color: AppColors.danger600),
                const SizedBox(width: 8),
                const Expanded(child: Text('Could not load municipalities.')),
                TextButton(onPressed: () => ref.invalidate(municipalitiesProvider), child: const Text('Retry')),
              ],
            ),
          ),
          data: (items) => DropdownButtonFormField<int?>(
            initialValue: _municipalityId,
            decoration: const InputDecoration(labelText: 'Preferred municipality'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Any')),
              ...items.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))),
            ],
            onChanged: (value) => setState(() => _municipalityId = value),
          ),
        ),
        const SizedBox(height: 20),
        Text('Work location', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        const Text('Tap the map to drop a pin — used to estimate commute time (straight-line estimate).'),
        const SizedBox(height: 8),
        WorkLocationPicker(
          initialLat: _workLat,
          initialLng: _workLng,
          onChanged: (lat, lng) => setState(() {
            _workLat = lat;
            _workLng = lng;
          }),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _workLabelController,
          decoration: const InputDecoration(labelText: 'Work location label (optional)', hintText: 'e.g. Durbar Marg office'),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int?>(
          initialValue: _commuteLimit,
          decoration: const InputDecoration(labelText: 'Max commute (minutes)'),
          items: [
            const DropdownMenuItem(value: null, child: Text('No limit')),
            ...[15, 30, 45, 60, 90, 120].map((n) => DropdownMenuItem(value: n, child: Text('$n min'))),
          ],
          onChanged: (value) => setState(() => _commuteLimit = value),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _familySizeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Family size (optional)'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Needs a school nearby'),
          value: _requiresSchool,
          onChanged: (value) => setState(() => _requiresSchool = value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Needs parking'),
          value: _requiresParking,
          onChanged: (value) => setState(() => _requiresParking = value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Buying as an investment'),
          value: _investmentPurpose,
          onChanged: (value) => setState(() => _investmentPurpose = value),
        ),
        const SizedBox(height: 12),
        Text('What matters to you', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kLifestyleTags.entries.map((entry) {
            final selected = _lifestyleTags.contains(entry.key);
            return FilterChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (value) => setState(() {
                if (value) {
                  _lifestyleTags.add(entry.key);
                } else {
                  _lifestyleTags.remove(entry.key);
                }
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        AppButton(label: 'Save & find matches', isLoading: _saving, onPressed: _save),
      ],
    );
  }
}
