import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_badge.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/error_state.dart';
import '../../../../widgets/skeleton.dart';
import '../application/admin_conversations_providers.dart';
import '../data/models/admin_conversation.dart';

/// Admin conversation moderation list. Filters by status + a name/email
/// search, polls every 15s (see `adminConversationsListProvider`).
class AdminConversationsScreen extends ConsumerStatefulWidget {
  const AdminConversationsScreen({super.key});

  @override
  ConsumerState<AdminConversationsScreen> createState() => _AdminConversationsScreenState();
}

class _AdminConversationsScreenState extends ConsumerState<AdminConversationsScreen> {
  late final _searchController = TextEditingController(text: ref.read(adminConversationsQueryProvider));

  static final _dateFormat = DateFormat('d MMM, h:mm a');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch(String value) {
    ref.read(adminConversationsQueryProvider.notifier).state = value.trim();
    ref.read(adminConversationsPageProvider.notifier).state = 1;
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(adminConversationsStatusFilterProvider);
    final page = ref.watch(adminConversationsPageProvider);
    final result = ref.watch(adminConversationsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Conversations')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _submitSearch,
                  decoration: InputDecoration(
                    hintText: 'Search buyer or owner name/email',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              _submitSearch('');
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Status:'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: status,
                        isDense: true,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All')),
                          DropdownMenuItem(value: 'open', child: Text('Open')),
                          DropdownMenuItem(value: 'closed', child: Text('Closed')),
                        ],
                        onChanged: (value) {
                          ref.read(adminConversationsStatusFilterProvider.notifier).state = value;
                          ref.read(adminConversationsPageProvider.notifier).state = 1;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: result.when(
              loading: () => ListView(
                padding: const EdgeInsets.all(16),
                children: List.generate(
                  6,
                  (_) => const Padding(padding: EdgeInsets.only(bottom: 12), child: Skeleton(height: 76)),
                ),
              ),
              error: (error, _) => ErrorState(
                message: 'Could not load conversations.',
                onRetry: () => ref.invalidate(adminConversationsListProvider),
              ),
              data: (data) => data.items.isEmpty
                  ? const EmptyState(title: 'No conversations found', icon: Icons.forum_outlined)
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(adminConversationsListProvider),
                      child: ListView.separated(
                        itemCount: data.items.length,
                        separatorBuilder: (context, _) => const Divider(height: 1),
                        itemBuilder: (context, index) =>
                            _ConversationTile(conversation: data.items[index], dateFormat: _dateFormat),
                      ),
                    ),
            ),
          ),
          result.maybeWhen(
            data: (data) => data.lastPage > 1
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: page > 1
                              ? () => ref.read(adminConversationsPageProvider.notifier).state = page - 1
                              : null,
                          child: const Text('Previous'),
                        ),
                        Text('Page $page of ${data.lastPage}'),
                        TextButton(
                          onPressed: page < data.lastPage
                              ? () => ref.read(adminConversationsPageProvider.notifier).state = page + 1
                              : null,
                          child: const Text('Next'),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.dateFormat});

  final AdminConversation conversation;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final buyer = conversation.buyer?.name ?? 'Unknown buyer';
    final owner = conversation.owner?.name ?? 'Unknown owner';

    return ListTile(
      onTap: () => context.push('/admin/conversations/${conversation.id}'),
      title: Text('$buyer ↔ $owner', style: Theme.of(context).textTheme.titleSmall),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(conversation.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (conversation.lastMessagePreview != null)
            Text(
              conversation.lastMessagePreview!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AppBadge(
            label: conversation.status,
            tone: conversation.status == 'open' ? BadgeTone.trust : BadgeTone.neutral,
          ),
          if (conversation.lastMessageAt != null) ...[
            const SizedBox(height: 4),
            Text(
              dateFormat.format(DateTime.parse(conversation.lastMessageAt!)),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
            ),
          ],
        ],
      ),
    );
  }
}
