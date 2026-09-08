import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/error_state.dart';
import '../../auth/application/auth_controller.dart';
import '../application/neighborhoods_providers.dart';
import '../data/models/community_note.dart';
import '../data/models/neighborhood_poi.dart';
import '../data/models/neighborhood_profile.dart';
import '../data/models/neighborhood_score.dart';

/// Mirrors frontend/src/pages/Neighborhoods/NeighborhoodProfile.tsx: score
/// bars, a POI list, approved community notes, and a submission form gated
/// three ways (guest -> log in; logged in but not phone-verified -> verify;
/// otherwise the real form).
class NeighborhoodProfileScreen extends ConsumerWidget {
  const NeighborhoodProfileScreen({super.key, required this.neighborhoodId});

  final int neighborhoodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(neighborhoodProfileProvider(neighborhoodId));

    return Scaffold(
      appBar: AppBar(title: const Text('Neighborhood')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: 'Could not load this neighborhood.',
          onRetry: () => ref.invalidate(neighborhoodProfileProvider(neighborhoodId)),
        ),
        data: (data) => _ProfileBody(profile: data),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.profile});

  final NeighborhoodProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = profile.score;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(profile.name, style: Theme.of(context).textTheme.headlineSmall),
            ),
            if (profile.isCurated) const AppBadge(label: 'Curated', tone: BadgeTone.trust),
          ],
        ),
        Text(
          '${profile.ward.municipality} · Ward ${profile.ward.wardNumber}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink700),
        ),
        if (score != null) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Text('Neighborhood score', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                '${score.overallScore}/10',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.trust700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final factor in score.factors) _ScoreBar(factor: factor),
        ],
        if (profile.pois.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Nearby points of interest', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final poi in profile.pois) _PoiTile(poi: poi),
        ],
        const SizedBox(height: 24),
        Text('Community notes', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (profile.communityNotes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No community notes yet.'),
          )
        else
          for (final note in profile.communityNotes) _CommunityNoteTile(note: note),
        const SizedBox(height: 12),
        _SubmissionForm(neighborhoodId: profile.id),
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.factor});

  final NeighborhoodScoreFactor factor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(factor.label, style: Theme.of(context).textTheme.bodySmall)),
              Text('${factor.score}/10', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: factor.score / 10,
              minHeight: 6,
              backgroundColor: AppColors.stone200,
              color: AppColors.trust600,
            ),
          ),
          if (factor.notes != null && factor.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                factor.notes!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
              ),
            ),
        ],
      ),
    );
  }
}

class _PoiTile extends StatelessWidget {
  const _PoiTile({required this.poi});

  final NeighborhoodPoi poi;

  IconData get _icon => switch (poi.poiType) {
    'school' => Icons.school_outlined,
    'hospital' => Icons.local_hospital_outlined,
    'market' => Icons.storefront_outlined,
    'transport_stop' => Icons.directions_bus_outlined,
    'bank' => Icons.account_balance_outlined,
    _ => Icons.place_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(_icon, color: AppColors.ink700),
      title: Text(poi.name),
      subtitle: Text(poi.typeLabel),
    );
  }
}

class _CommunityNoteTile extends StatelessWidget {
  const _CommunityNoteTile({required this.note});

  final CommunityNote note;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppBadge(label: note.categoryLabel, tone: BadgeTone.neutral),
            const SizedBox(height: 6),
            Text(note.body),
          ],
        ),
      ),
    );
  }
}

class _SubmissionForm extends ConsumerStatefulWidget {
  const _SubmissionForm({required this.neighborhoodId});

  final int neighborhoodId;

  @override
  ConsumerState<_SubmissionForm> createState() => _SubmissionFormState();
}

class _SubmissionFormState extends ConsumerState<_SubmissionForm> {
  final _bodyController = TextEditingController();
  String _category = 'other';
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(neighborhoodsRepositoryProvider)
          .submitCommunityNote(widget.neighborhoodId, category: _category, body: body);
      if (mounted) {
        setState(() {
          _submitted = true;
          _bodyController.clear();
        });
      }
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;

    if (user == null) {
      return OutlinedButton(
        onPressed: () => context.push('/login'),
        child: const Text('Log in to contribute'),
      );
    }
    if (!user.phoneVerified) {
      return OutlinedButton(
        onPressed: () => context.push('/settings'),
        child: const Text('Verify your phone number to contribute'),
      );
    }
    if (_submitted) {
      return const Text('Thanks — your note is pending admin review.');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share something locals should know', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: kCommunityNoteCategories.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) => setState(() => _category = value ?? _category),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Your note', alignLabelWithHint: true),
              onChanged: (_) => setState(() {}),
            ),
            AppButton(label: 'Submit', isLoading: _submitting, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
