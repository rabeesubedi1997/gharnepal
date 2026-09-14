import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/npr_formatter.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_badge.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../application/agency_dashboard_providers.dart';
import '../data/models/agency_dashboard_listing.dart';
import '../data/models/agency_inquiry.dart';
import '../data/models/agency_overview.dart';
import '../data/models/agency_site_visit.dart';

/// A self-service dashboard for the current user's own agency — mirrors
/// frontend/src/pages/AgencyDashboard.tsx: portfolio stats, buyer inquiries
/// feed, site-visit calendar, and alert-subscriber reach, all real queries
/// against `/agency/dashboard/*`. Deliberately not built here either
/// (matching web's own scope cut): a WhatsApp-vs-portal inquiry channel
/// split, a weekly-digest open-rate, an "NRI buyer match index", CSV/MLS
/// bulk import, or per-branch analytics — none of these have real backing
/// data on this platform.
class AgencyDashboardScreen extends ConsumerWidget {
  const AgencyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(agencyOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Agency dashboard')),
      body: overview.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          // A 404 means "not a member of any agency" — not a real error.
          final isNotMember = error is ApiException && error.statusCode == 404;
          if (isNotMember) {
            return const EmptyState(
              title: 'No agency dashboard for your account',
              message: 'This dashboard is only available to members of a registered agency.',
              icon: Icons.business_outlined,
            );
          }
          return ErrorState(
            message: 'Could not load your agency dashboard.',
            onRetry: () => ref.invalidate(agencyOverviewProvider),
          );
        },
        data: (data) => _DashboardBody(overview: data),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.overview});

  final AgencyOverview overview;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _AgencyHeader(agency: overview.agency),
          ),
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Listings'),
              Tab(text: 'Inquiries'),
              Tab(text: 'Site visits'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _OverviewTab(overview: overview),
                const _ListingsTab(),
                const _InquiriesTab(),
                const _SiteVisitsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgencyHeader extends StatelessWidget {
  const _AgencyHeader({required this.agency});

  final AgencyDashboardAgency agency;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: agency.logoUrl != null
              ? CachedNetworkImage(imageUrl: agency.logoUrl!, width: 48, height: 48, fit: BoxFit.cover)
              : Container(
                  width: 48,
                  height: 48,
                  color: AppColors.trust100,
                  child: const Icon(Icons.business, color: AppColors.trust700),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      agency.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (agency.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified, size: 16, color: AppColors.success600),
                  ],
                ],
              ),
              Text(
                [
                  if (agency.registrationNumber != null) 'Reg. ${agency.registrationNumber}',
                  if (agency.foundedYear != null) 'Est. ${agency.foundedYear}',
                  '${agency.memberCount} member${agency.memberCount == 1 ? '' : 's'}',
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.overview});

  final AgencyOverview overview;

  @override
  Widget build(BuildContext context) {
    final tiles = <(IconData, String, String)>[
      (
        Icons.apartment_outlined,
        'Active portfolio',
        '${overview.portfolio.activeCount} (+${overview.portfolio.newThisWeek} this week)',
      ),
      (
        Icons.forum_outlined,
        'Inquiries (30d)',
        '${overview.inquiries30d.count}'
            '${overview.inquiries30d.responseRatePct != null ? ' · ${overview.inquiries30d.responseRatePct}% response rate' : ''}',
      ),
      (
        Icons.calendar_month_outlined,
        'Site visits',
        '${overview.siteVisits.upcoming7d} upcoming (${overview.siteVisits.today} today)',
      ),
      (
        Icons.payments_outlined,
        'For-sale portfolio value',
        '${NprFormatter.formatCompact(overview.forSalePortfolioValue.total)} (${overview.forSalePortfolioValue.listingCount} listings)',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final tile in tiles)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.trust100, borderRadius: BorderRadius.circular(10)),
                    child: Icon(tile.$1, color: AppColors.trust700),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tile.$3, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        Text(tile.$2, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (overview.portfolio.byCity.isNotEmpty) ...[
          Text('Top cities', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final city in overview.portfolio.byCity)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text(city.city), Text('${city.count}')],
              ),
            ),
          const SizedBox(height: 12),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_outlined, color: AppColors.trust700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${overview.alertReach}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        'Alert subscribers who could see your next listing',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ListingsTab extends ConsumerStatefulWidget {
  const _ListingsTab();

  @override
  ConsumerState<_ListingsTab> createState() => _ListingsTabState();
}

class _ListingsTabState extends ConsumerState<_ListingsTab> {
  AgencyListingsFilter _filter = const AgencyListingsFilter();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agencyListingsProvider(_filter));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search title or slug',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onSubmitted: (value) =>
                    setState(() => _filter = _filter.copyWith(search: value, clearSearch: value.isEmpty)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _filter.category,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Category', isDense: true),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All categories')),
                        DropdownMenuItem(value: 'houses', child: Text('Houses')),
                        DropdownMenuItem(value: 'land', child: Text('Land')),
                        DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
                      ],
                      onChanged: (value) => setState(
                        () => _filter = _filter.copyWith(category: value, clearCategory: value == null),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _filter.sort,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Sort', isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'newest', child: Text('Newest')),
                        DropdownMenuItem(value: 'leads', child: Text('Most leads')),
                        DropdownMenuItem(value: 'price_high', child: Text('Price: high')),
                        DropdownMenuItem(value: 'price_low', child: Text('Price: low')),
                      ],
                      onChanged: (value) => setState(() => _filter = _filter.copyWith(sort: value)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorState(
              message: 'Could not load listings.',
              onRetry: () => ref.invalidate(agencyListingsProvider(_filter)),
            ),
            data: (data) => data.items.isEmpty
                ? const EmptyState(title: 'No listings match these filters', icon: Icons.apartment_outlined)
                : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.extentAfter < 200) {
                        ref.read(agencyListingsProvider(_filter).notifier).loadMore();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: data.items.length + (data.isLoadingMore ? 1 : 0),
                      separatorBuilder: (context, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index >= data.items.length) {
                          return const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()));
                        }
                        return _AgencyListingTile(listing: data.items[index]);
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _AgencyListingTile extends StatelessWidget {
  const _AgencyListingTile({required this.listing});

  final AgencyDashboardListing listing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/listings/${listing.slug}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: listing.coverImageUrl != null
                    ? CachedNetworkImage(imageUrl: listing.coverImageUrl!, width: 56, height: 56, fit: BoxFit.cover)
                    : Container(
                        width: 56,
                        height: 56,
                        color: AppColors.stone200,
                        child: const Icon(Icons.home_outlined, color: AppColors.ink700),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${NprFormatter.formatCompact(listing.price)}${listing.priceSuffix}'
                      '${listing.location?.municipality != null ? ' · ${listing.location!.municipality}' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700),
                    ),
                    Text(
                      '${listing.inquiriesCount} inquiries · ${listing.leadsCount} leads',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.trust700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InquiriesTab extends ConsumerWidget {
  const _InquiriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inquiries = ref.watch(agencyInquiriesProvider);

    return inquiries.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorState(
        message: 'Could not load inquiries.',
        onRetry: () => ref.invalidate(agencyInquiriesProvider),
      ),
      data: (items) => items.isEmpty
          ? const EmptyState(title: 'No buyer inquiries yet', icon: Icons.forum_outlined)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (context, _) => const Divider(),
              itemBuilder: (context, index) => _InquiryTile(inquiry: items[index]),
            ),
    );
  }
}

class _InquiryTile extends StatelessWidget {
  const _InquiryTile({required this.inquiry});

  final AgencyInquiry inquiry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(inquiry.buyerName ?? 'A buyer'),
      subtitle: Text(inquiry.listingTitle ?? 'Unknown listing'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${inquiry.messageCount} msgs', style: Theme.of(context).textTheme.bodySmall),
          if (inquiry.lastMessageAt != null)
            Text(inquiry.lastMessageAt!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink700)),
        ],
      ),
      onTap: inquiry.listingSlug != null ? () => context.push('/listings/${inquiry.listingSlug}') : null,
    );
  }
}

class _SiteVisitsTab extends ConsumerWidget {
  const _SiteVisitsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visits = ref.watch(agencySiteVisitsProvider);

    return visits.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorState(
        message: 'Could not load site visits.',
        onRetry: () => ref.invalidate(agencySiteVisitsProvider),
      ),
      data: (items) => items.isEmpty
          ? const EmptyState(title: 'No upcoming site visits', icon: Icons.calendar_month_outlined)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (context, _) => const Divider(),
              itemBuilder: (context, index) => _SiteVisitTile(visit: items[index]),
            ),
    );
  }
}

class _SiteVisitTile extends StatelessWidget {
  const _SiteVisitTile({required this.visit});

  final AgencySiteVisit visit;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AppBadge(
        label: visit.isConfirmed ? 'Confirmed' : 'Pending',
        tone: visit.isConfirmed ? BadgeTone.success : BadgeTone.warning,
      ),
      title: Text(visit.listingTitle ?? 'Unknown listing'),
      subtitle: Text(
        [
          if (visit.when != null) visit.when! else 'Unscheduled',
          if (visit.municipality != null) visit.municipality!,
          if (visit.requesterName != null) 'with ${visit.requesterName}',
        ].join(' · '),
      ),
      onTap: visit.listingSlug != null ? () => context.push('/listings/${visit.listingSlug}') : null,
    );
  }
}
