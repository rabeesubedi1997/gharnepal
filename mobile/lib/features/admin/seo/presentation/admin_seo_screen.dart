import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/app_badge.dart';
import '../../../../widgets/empty_state.dart';
import '../../../../widgets/error_state.dart';
import '../../../../widgets/skeleton.dart';
import '../application/admin_seo_providers.dart';
import '../data/models/seo_page_summary.dart';

/// Lists every real page on the site by its synthetic `page_key`, with a
/// type filter and a label/key search.
class AdminSeoScreen extends ConsumerStatefulWidget {
  const AdminSeoScreen({super.key});

  @override
  ConsumerState<AdminSeoScreen> createState() => _AdminSeoScreenState();
}

class _AdminSeoScreenState extends ConsumerState<AdminSeoScreen> {
  late final _searchController = TextEditingController(text: ref.read(adminSeoQueryProvider));

  static const _types = ['static', 'listing', 'neighborhood', 'agency', 'blog'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch(String value) {
    ref.read(adminSeoQueryProvider.notifier).state = value.trim();
  }

  @override
  Widget build(BuildContext context) {
    final type = ref.watch(adminSeoTypeFilterProvider);
    final pages = ref.watch(adminSeoPagesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SEO pages')),
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
                  decoration: const InputDecoration(hintText: 'Search label or page key', prefixIcon: Icon(Icons.search), isDense: true),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Type:'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: type,
                        isDense: true,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All')),
                          for (final t in _types) DropdownMenuItem(value: t, child: Text(t)),
                        ],
                        onChanged: (value) => ref.read(adminSeoTypeFilterProvider.notifier).state = value,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: pages.when(
              loading: () => ListView(
                padding: const EdgeInsets.all(16),
                children: List.generate(
                  6,
                  (_) => const Padding(padding: EdgeInsets.only(bottom: 12), child: Skeleton(height: 64)),
                ),
              ),
              error: (error, _) =>
                  ErrorState(message: 'Could not load SEO pages.', onRetry: () => ref.invalidate(adminSeoPagesListProvider)),
              data: (items) => items.isEmpty
                  ? const EmptyState(title: 'No pages found', icon: Icons.travel_explore_outlined)
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(adminSeoPagesListProvider),
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (context, _) => const Divider(height: 1),
                        itemBuilder: (context, index) => _PageRow(page: items[index]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageRow extends StatelessWidget {
  const _PageRow({required this.page});

  final SeoPageSummary page;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.push('/admin/seo/${Uri.encodeComponent(page.pageKey)}'),
      title: Text(page.label),
      subtitle: Text(page.path, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (page.hasOverride)
            AppBadge(
              label: page.status ?? 'override',
              tone: page.status == 'published' ? BadgeTone.success : BadgeTone.warning,
            )
          else
            const AppBadge(label: 'Default', tone: BadgeTone.neutral),
          const SizedBox(height: 4),
          Text(page.pageType, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700)),
        ],
      ),
    );
  }
}
