import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_badge.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/error_state.dart';
import '../application/admin_agencies_providers.dart';
import '../data/models/admin_agency.dart';

/// Admin agencies list: `GET /admin/agencies` with a status filter, plus
/// Verify/Suspend actions.
class AdminAgenciesScreen extends ConsumerWidget {
  const AdminAgenciesScreen({super.key});

  BadgeTone _statusTone(String status) => switch (status) {
    'active' => BadgeTone.success,
    'suspended' => BadgeTone.danger,
    _ => BadgeTone.warning, // pending
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agenciesAsync = ref.watch(adminAgenciesListProvider);
    final page = ref.watch(adminAgenciesPageProvider);
    final status = ref.watch(adminAgenciesStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Agencies')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: DropdownButtonFormField<String?>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All statuses')),
                for (final s in kAdminAgencyStatuses) DropdownMenuItem(value: s, child: Text(s)),
              ],
              onChanged: (value) {
                ref.read(adminAgenciesStatusFilterProvider.notifier).state = value;
                ref.read(adminAgenciesPageProvider.notifier).state = 1;
              },
            ),
          ),
          Expanded(
            child: agenciesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorState(
                message: 'Could not load agencies.',
                onRetry: () => ref.invalidate(adminAgenciesListProvider),
              ),
              data: (result) => result.items.isEmpty
                  ? const EmptyState(title: 'No agencies found', icon: Icons.apartment_outlined)
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: result.items.length,
                            separatorBuilder: (context, _) => const SizedBox(height: 10),
                            itemBuilder: (context, index) => _AgencyCard(
                              agency: result.items[index],
                              statusTone: _statusTone(result.items[index].status),
                            ),
                          ),
                        ),
                        if (result.lastPage > 1)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: page > 1
                                      ? () => ref.read(adminAgenciesPageProvider.notifier).state = page - 1
                                      : null,
                                  child: const Text('Previous'),
                                ),
                                Text('Page $page of ${result.lastPage}'),
                                TextButton(
                                  onPressed: page < result.lastPage
                                      ? () => ref.read(adminAgenciesPageProvider.notifier).state = page + 1
                                      : null,
                                  child: const Text('Next'),
                                ),
                              ],
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

class _AgencyCard extends ConsumerStatefulWidget {
  const _AgencyCard({required this.agency, required this.statusTone});

  final AdminAgency agency;
  final BadgeTone statusTone;

  @override
  ConsumerState<_AgencyCard> createState() => _AgencyCardState();
}

class _AgencyCardState extends ConsumerState<_AgencyCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(adminAgenciesListProvider);
    } catch (error) {
      if (mounted) {
        final message = error is ApiException ? error.message : 'Something went wrong. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final agency = widget.agency;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: agency.logoUrl != null
                  ? CachedNetworkImage(imageUrl: agency.logoUrl!, width: 52, height: 52, fit: BoxFit.cover)
                  : Container(
                      width: 52,
                      height: 52,
                      color: AppColors.stone200,
                      child: const Icon(Icons.apartment_outlined),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(agency.name, style: Theme.of(context).textTheme.titleSmall),
                      ),
                      AppBadge(label: agency.status, tone: widget.statusTone),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${agency.memberCount} member${agency.memberCount == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (!agency.isVerified)
                        FilledButton.tonal(
                          onPressed: _busy ? null : () => _run(() => ref.read(adminAgenciesRepositoryProvider).verify(agency.id)),
                          child: const Text('Verify'),
                        ),
                      if (agency.status != 'suspended')
                        OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _run(() => ref.read(adminAgenciesRepositoryProvider).suspend(agency.id)),
                          child: const Text('Suspend'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
