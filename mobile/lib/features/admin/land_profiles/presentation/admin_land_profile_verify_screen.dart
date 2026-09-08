import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_button.dart';
import '../../../../widgets/error_state.dart';
import '../../../listings/data/models/land_profile.dart';
import '../application/admin_land_profiles_providers.dart';

const _documentVerificationStatuses = ['unverified', 'partial', 'verified'];

String _titleCase(String value) =>
    value.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

/// Read-only display of one property's `LandProfile`, plus the one
/// admin-settable field: `document_verification_status`. Reachable directly
/// with just a property ID (e.g. from a listing moderation detail screen
/// elsewhere) — it does not assume it was reached via
/// [AdminTrustFactorsScreen]-style navigation.
class AdminLandProfileVerifyScreen extends ConsumerWidget {
  const AdminLandProfileVerifyScreen({super.key, required this.propertyId});

  final int propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(adminLandProfileProvider(propertyId));

    return Scaffold(
      appBar: AppBar(title: const Text('Land profile verification')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: 'Could not load this property\'s land profile.',
          onRetry: () => ref.invalidate(adminLandProfileProvider(propertyId)),
        ),
        data: (data) => _LandProfileBody(propertyId: propertyId, profile: data),
      ),
    );
  }
}

class _LandProfileBody extends ConsumerStatefulWidget {
  const _LandProfileBody({required this.propertyId, required this.profile});

  final int propertyId;
  final LandProfile profile;

  @override
  ConsumerState<_LandProfileBody> createState() => _LandProfileBodyState();
}

class _LandProfileBodyState extends ConsumerState<_LandProfileBody> {
  late String _status = widget.profile.documentVerificationStatus;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(adminLandProfilesRepositoryProvider).verify(widget.propertyId, _status);
      ref.invalidate(adminLandProfileProvider(widget.propertyId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification status saved.')));
      }
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
    final profile = widget.profile;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Completeness', style: Theme.of(context).textTheme.titleMedium),
            ),
            Text('${profile.completenessPercent.round()}%'),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (profile.completenessPercent / 100).clamp(0, 1),
            minHeight: 8,
            backgroundColor: AppColors.stone200,
            color: AppColors.trust600,
          ),
        ),
        const SizedBox(height: 20),
        _InfoRow(label: 'Kitta number', value: profile.kittaNumber ?? 'Not provided'),
        _InfoRow(label: 'Lalpurja available', value: _titleCase(profile.lalpurjaAvailable)),
        if (profile.lalpurjaDocumentUrl != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: OutlinedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(profile.lalpurjaDocumentUrl!),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.description_outlined),
              label: const Text('View lalpurja document'),
            ),
          ),
        _InfoRow(label: 'Road access', value: profile.roadAccess ? 'Yes' : 'No'),
        _InfoRow(
          label: 'Road width',
          value: profile.roadWidthMeters != null ? '${profile.roadWidthMeters} m' : 'Not provided',
        ),
        _InfoRow(label: 'Road type', value: _titleCase(profile.roadType)),
        _InfoRow(label: 'Water access', value: _titleCase(profile.waterAccess)),
        _InfoRow(label: 'Electricity access', value: profile.electricityAccess ? 'Yes' : 'No'),
        _InfoRow(label: 'Drainage access', value: _titleCase(profile.drainageAccess)),
        _InfoRow(label: 'Land classification', value: _titleCase(profile.landClassification)),
        _InfoRow(label: 'Flood risk', value: _titleCase(profile.floodRisk)),
        _InfoRow(label: 'Landslide risk', value: _titleCase(profile.landslideRisk)),
        _InfoRow(label: 'Nearby development notes', value: profile.nearbyDevelopmentNotes ?? 'None'),
        if (profile.verifiedAt != null) _InfoRow(label: 'Last verified at', value: profile.verifiedAt!),
        const SizedBox(height: 20),
        Text('Document verification status', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            for (final status in _documentVerificationStatuses)
              ButtonSegment(value: status, label: Text(_titleCase(status))),
          ],
          selected: {_status},
          onSelectionChanged: (value) => setState(() => _status = value.first),
        ),
        const SizedBox(height: 16),
        AppButton(label: 'Save', isLoading: _saving, onPressed: _save),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink700)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
