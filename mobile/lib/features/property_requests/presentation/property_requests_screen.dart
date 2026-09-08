import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../../auth/application/auth_controller.dart';
import '../../messaging/presentation/start_conversation_sheet.dart';
import '../application/property_requests_providers.dart';
import '../data/models/property_request.dart';
import 'create_property_request_sheet.dart';

/// Mirrors frontend/src/pages/PropertyRequests/index.tsx: a public
/// demand-side board plus a "Mine" tab for requests the user has posted.
class PropertyRequestsScreen extends StatelessWidget {
  const PropertyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Property requests'),
          bottom: const TabBar(tabs: [Tab(text: 'Board'), Tab(text: 'Mine')]),
        ),
        body: const TabBarView(children: [_BoardTab(), _MineTab()]),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton.extended(
            onPressed: () async {
              final consumer = ProviderScope.containerOf(context, listen: false);
              if (consumer.read(authControllerProvider).valueOrNull == null) {
                if (context.mounted) context.go('/login');
                return;
              }
              final posted = await CreatePropertyRequestSheet.show(context);
              if (posted == true) {
                consumer.invalidate(myPropertyRequestsProvider);
                consumer.invalidate(propertyRequestsBoardProvider);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Post request'),
          ),
        ),
      ),
    );
  }
}

class _BoardTab extends ConsumerWidget {
  const _BoardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(propertyRequestsBoardProvider);

    return requests.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorState(
        message: 'Could not load property requests.',
        onRetry: () => ref.invalidate(propertyRequestsBoardProvider),
      ),
      data: (items) => items.isEmpty
          ? const EmptyState(title: 'No open requests right now', icon: Icons.inbox_outlined)
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(propertyRequestsBoardProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                itemBuilder: (context, index) => _RequestCard(request: items[index]),
              ),
            ),
    );
  }
}

class _MineTab extends ConsumerWidget {
  const _MineTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(authControllerProvider).valueOrNull != null;
    if (!loggedIn) {
      return const EmptyState(title: 'Log in to see your requests', icon: Icons.lock_outline);
    }

    final requests = ref.watch(myPropertyRequestsProvider);

    return requests.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorState(
        message: 'Could not load your requests.',
        onRetry: () => ref.invalidate(myPropertyRequestsProvider),
      ),
      data: (items) => items.isEmpty
          ? const EmptyState(title: "You haven't posted a request yet", icon: Icons.inbox_outlined)
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(myPropertyRequestsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                itemBuilder: (context, index) => _RequestCard(request: items[index], mine: true),
              ),
            ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  const _RequestCard({required this.request, this.mine = false});

  final PropertyRequest request;
  final bool mine;

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _busy = false;

  String _budgetLabel(PropertyRequest r) {
    if (r.budgetMin == null && r.budgetMax == null) return 'Budget flexible';
    if (r.budgetMin != null && r.budgetMax != null) return 'Rs ${r.budgetMin} – ${r.budgetMax}';
    return 'Rs ${r.budgetMin ?? r.budgetMax}${r.budgetMax == null ? '+' : ' max'}';
  }

  Future<void> _respond() async {
    if (ref.read(authControllerProvider).valueOrNull == null) {
      context.go('/login');
      return;
    }
    final conversationId = await StartConversationSheet.show(
      context,
      propertyRequestId: widget.request.id,
      title: 'Respond to this request',
    );
    if (conversationId != null && mounted) {
      context.push('/messages/$conversationId');
    }
  }

  Future<void> _close() async {
    setState(() => _busy = true);
    try {
      await ref.read(propertyRequestsRepositoryProvider).close(widget.request.id);
      ref.invalidate(myPropertyRequestsProvider);
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
    final request = widget.request;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppBadge(
                  label: request.purpose == 'rent' ? 'Looking to rent' : 'Looking to buy',
                  tone: BadgeTone.trust,
                ),
                const Spacer(),
                if (!request.isOpen) const AppBadge(label: 'Closed', tone: BadgeTone.neutral),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              [
                if (request.propertyType != null) request.propertyType!,
                if (request.municipality != null) 'in ${request.municipality}',
              ].join(' '),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(_budgetLabel(request), style: Theme.of(context).textTheme.bodyMedium),
            if (request.bedroomsMin != null)
              Text('${request.bedroomsMin}+ bedrooms', style: Theme.of(context).textTheme.bodySmall),
            if (request.notes != null && request.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(request.notes!, style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (request.postedBy != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Posted by ${request.postedBy}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
                ),
              ),
            const SizedBox(height: 10),
            if (widget.mine && request.isOpen)
              OutlinedButton(
                onPressed: _busy ? null : _close,
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger600),
                child: const Text('Close request'),
              )
            else if (!widget.mine && !request.isMine && request.isOpen)
              FilledButton(onPressed: _respond, child: const Text('Respond')),
          ],
        ),
      ),
    );
  }
}
