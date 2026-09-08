import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/error_state.dart';
import '../../../neighborhoods/application/neighborhoods_providers.dart';
import '../../../neighborhoods/data/models/neighborhood_poi.dart';
import '../../../neighborhoods/data/models/neighborhood_profile.dart';
import '../../../neighborhoods/data/models/neighborhood_score.dart';
import '../application/admin_neighborhood_scores_providers.dart';

/// Mirrors the website's combined neighborhood-scores admin page: pick a
/// neighborhood (reusing the same picker list as the public
/// `NeighborhoodsScreen`), then edit its 11 score factors and its POIs, both
/// against the same loaded `NeighborhoodProfile`
/// (`neighborhoodProfileProvider`, reused from the consumer feature).
class AdminNeighborhoodScoresScreen extends ConsumerStatefulWidget {
  const AdminNeighborhoodScoresScreen({super.key});

  @override
  ConsumerState<AdminNeighborhoodScoresScreen> createState() => _AdminNeighborhoodScoresScreenState();
}

class _AdminNeighborhoodScoresScreenState extends ConsumerState<AdminNeighborhoodScoresScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  int? _selectedId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = _selectedId;
    return Scaffold(
      appBar: AppBar(title: const Text('Neighborhood scores')),
      body: selectedId == null ? _buildPicker() : _buildEditor(selectedId),
    );
  }

  Widget _buildPicker() {
    final neighborhoods = ref.watch(neighborhoodsListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by name or city',
            ),
            onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: neighborhoods.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorState(
              message: 'Could not load neighborhoods.',
              onRetry: () => ref.invalidate(neighborhoodsListProvider),
            ),
            data: (items) {
              final filtered = _query.isEmpty
                  ? items
                  : items.where((n) => n.searchHaystack.contains(_query)).toList();

              if (filtered.isEmpty) {
                return const EmptyState(title: 'No neighborhoods found', icon: Icons.location_city_outlined);
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: filtered.length,
                separatorBuilder: (context, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final neighborhood = filtered[index];
                  return Card(
                    child: ListTile(
                      title: Text(neighborhood.name),
                      subtitle: Text('${neighborhood.ward.municipality} · Ward ${neighborhood.ward.wardNumber}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => setState(() => _selectedId = neighborhood.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEditor(int id) {
    final profile = ref.watch(neighborhoodProfileProvider(id));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  profile.valueOrNull?.name ?? 'Neighborhood',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedId = null),
                child: const Text('Change'),
              ),
            ],
          ),
        ),
        Expanded(
          child: profile.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorState(
              message: 'Could not load this neighborhood.',
              onRetry: () => ref.invalidate(neighborhoodProfileProvider(id)),
            ),
            data: (data) => _NeighborhoodEditor(key: ValueKey(data.id), profile: data),
          ),
        ),
      ],
    );
  }
}

/// Local, optimistic copy of the scores/POIs the admin is editing. Mutations
/// are applied to this local state directly rather than re-fetching the
/// whole profile after every save, so in-progress edits to one section
/// (e.g. a not-yet-saved score slider) survive an unrelated action (e.g.
/// deleting a POI) in the other section.
class _NeighborhoodEditor extends ConsumerStatefulWidget {
  const _NeighborhoodEditor({super.key, required this.profile});

  final NeighborhoodProfile profile;

  @override
  ConsumerState<_NeighborhoodEditor> createState() => _NeighborhoodEditorState();
}

class _NeighborhoodEditorState extends ConsumerState<_NeighborhoodEditor> {
  late Map<String, int> _scores;
  late Map<String, TextEditingController> _notesControllers;
  late List<NeighborhoodPoi> _pois;

  final _poiNameController = TextEditingController();
  final _poiLatController = TextEditingController();
  final _poiLngController = TextEditingController();
  String _poiType = kPoiTypes.keys.first;

  bool _savingScores = false;
  bool _addingPoi = false;
  int? _deletingPoiId;

  @override
  void initState() {
    super.initState();
    final factorsByKey = {for (final factor in widget.profile.score?.factors ?? const []) factor.key: factor};
    _scores = {for (final key in kNeighborhoodScoreFactors.keys) key: factorsByKey[key]?.score ?? 5};
    _notesControllers = {
      for (final key in kNeighborhoodScoreFactors.keys)
        key: TextEditingController(text: factorsByKey[key]?.notes ?? ''),
    };
    _pois = List.of(widget.profile.pois);
  }

  @override
  void dispose() {
    for (final controller in _notesControllers.values) {
      controller.dispose();
    }
    _poiNameController.dispose();
    _poiLatController.dispose();
    _poiLngController.dispose();
    super.dispose();
  }

  void _showError(Object error) {
    final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveScores() async {
    setState(() => _savingScores = true);
    try {
      final factors = [
        for (final key in kNeighborhoodScoreFactors.keys)
          NeighborhoodScoreFactor(
            key: key,
            score: _scores[key] ?? 5,
            notes: _notesControllers[key]!.text.trim().isEmpty ? null : _notesControllers[key]!.text.trim(),
          ),
      ];
      await ref.read(adminNeighborhoodScoresRepositoryProvider).saveScore(widget.profile.id, factors);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scores saved.')));
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _savingScores = false);
    }
  }

  Future<void> _addPoi() async {
    final name = _poiNameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _addingPoi = true);
    try {
      final latText = _poiLatController.text.trim();
      final lngText = _poiLngController.text.trim();
      final poi = await ref
          .read(adminNeighborhoodScoresRepositoryProvider)
          .createPoi(
            widget.profile.id,
            poiType: _poiType,
            name: name,
            lat: latText.isEmpty ? null : double.tryParse(latText),
            lng: lngText.isEmpty ? null : double.tryParse(lngText),
          );
      if (!mounted) return;
      setState(() {
        _pois = [..._pois, poi];
        _poiNameController.clear();
        _poiLatController.clear();
        _poiLngController.clear();
      });
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _addingPoi = false);
    }
  }

  Future<void> _deletePoi(NeighborhoodPoi poi) async {
    setState(() => _deletingPoiId = poi.id);
    try {
      await ref.read(adminNeighborhoodScoresRepositoryProvider).deletePoi(poi.id);
      if (!mounted) return;
      setState(() => _pois = _pois.where((p) => p.id != poi.id).toList());
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _deletingPoiId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scores', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Overall score is computed automatically from these factors.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
                ),
                for (final entry in kNeighborhoodScoreFactors.entries) _FactorEditor(
                  label: entry.value,
                  score: _scores[entry.key] ?? 5,
                  notesController: _notesControllers[entry.key]!,
                  onScoreChanged: (value) => setState(() => _scores[entry.key] = value),
                ),
                const SizedBox(height: 8),
                AppButton(label: 'Save all scores', isLoading: _savingScores, onPressed: _saveScores),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Points of interest', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_pois.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('No points of interest yet.', style: Theme.of(context).textTheme.bodyMedium),
                  )
                else
                  for (final poi in _pois)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(poi.name),
                      subtitle: Text(poi.typeLabel),
                      trailing: _deletingPoiId == poi.id
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.danger600),
                              onPressed: () => _deletePoi(poi),
                            ),
                    ),
                const Divider(height: 24),
                Text('Add a point of interest', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _poiType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: kPoiTypes.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (value) => setState(() => _poiType = value ?? _poiType),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _poiNameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _poiLatController,
                        keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                        decoration: const InputDecoration(labelText: 'Latitude (optional)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _poiLngController,
                        keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                        decoration: const InputDecoration(labelText: 'Longitude (optional)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Add point of interest',
                  isLoading: _addingPoi,
                  onPressed: _addPoi,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FactorEditor extends StatelessWidget {
  const _FactorEditor({
    required this.label,
    required this.score,
    required this.notesController,
    required this.onScoreChanged,
  });

  final String label;
  final int score;
  final TextEditingController notesController;
  final ValueChanged<int> onScoreChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
              Text('$score/10', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          Slider(
            value: score.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            label: '$score',
            onChanged: (value) => onScoreChanged(value.round()),
          ),
          TextField(
            controller: notesController,
            maxLength: 255,
            decoration: const InputDecoration(labelText: 'Notes (optional)', isDense: true),
          ),
        ],
      ),
    );
  }
}
