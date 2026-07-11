import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/admin_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/format_utils.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/wed_snack_bar.dart';

// ── Category helpers ──────────────────────────────────────────────────────────

IconData _iconForCategory(String category) {
  switch (category.toLowerCase()) {
    case 'venue':
      return Icons.apartment_outlined;
    case 'attire':
      return Icons.checkroom_outlined;
    case 'transport':
      return Icons.directions_bus_outlined;
    case 'catering':
      return Icons.restaurant_outlined;
    case 'floristry':
      return Icons.local_florist_outlined;
    default:
      return Icons.storefront_outlined;
  }
}

Color _bgForCategory(String category) {
  switch (category.toLowerCase()) {
    case 'venue':
      return AppColors.adminGreenBg;
    case 'attire':
      return AppColors.adminPinkBg;
    case 'transport':
      return AppColors.adminBlueBg;
    case 'catering':
      return AppColors.adminAmberBg;
    default:
      return AppColors.adminNeutralBg;
  }
}

Color _colorForCategory(String category) {
  switch (category.toLowerCase()) {
    case 'venue':
      return AppColors.adminGreen;
    case 'attire':
      return AppColors.adminPink;
    case 'transport':
      return AppColors.adminBlue;
    case 'catering':
      return AppColors.adminAmber;
    default:
      return AppColors.adminNeutral;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _searchQuery = _searchController.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminVendor> _filtered(List<AdminVendor> vendors) {
    if (_searchQuery.isEmpty) return vendors;
    return vendors
        .where((v) =>
            v.name.toLowerCase().contains(_searchQuery) ||
            v.category.toLowerCase().contains(_searchQuery) ||
            (v.location ?? '').toLowerCase().contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(adminOverviewProvider).valueOrNull ??
        const AdminOverview(
          activeCouples: 0,
          registeredVendors: 0,
          pendingVendorsCount: 0,
          verificationRate: 100,
          invitationsSentThisWeek: 0,
        );
    final pendingVendors = ref.watch(adminPendingVendorsProvider).valueOrNull ?? [];
    final flaggedFeedback =
        (ref.watch(adminFeedbackProvider).valueOrNull ?? []).where((f) => f.isFlagged).toList();
    final flaggedImages = ref.watch(adminFlaggedImagesProvider).valueOrNull ?? [];
    final totalFlaggedItems = flaggedFeedback.length + flaggedImages.length;
    final isWide = MediaQuery.sizeOf(context).width >= AppDimensions.tabletMin;
    final filteredVendors = _filtered(pendingVendors);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 68,
        titleSpacing: 24,
        title: Text(
          'Platform overview',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.forestGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (isWide) ...[
            SizedBox(
              width: 260,
              height: 40,
              child: TextField(
                controller: _searchController,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search vendors...',
                  hintStyle: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textHint, size: 18),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                        color: AppColors.forestGreen, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ] else
            IconButton(
              tooltip: 'Search',
              icon: const Icon(Icons.search_rounded,
                  color: AppColors.textPrimary, size: 22),
              onPressed: () => _showMobileSearch(context),
            ),
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.textPrimary, size: 22),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.teal,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                'AD',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Flagged content alert ────────────────────────────
            if (totalFlaggedItems > 0) ...[
              _FlaggedContentBanner(
                count: totalFlaggedItems,
                onReview: () => context.push(AppRoutes.adminModeration),
              ),
              const SizedBox(height: 20),
            ],

            // ── KPI cards ────────────────────────────────────────
            LayoutBuilder(
              builder: (_, constraints) {
                final wide = constraints.maxWidth >= AppDimensions.tabletMin;
                final cards = [
                  _KpiCard(
                    icon: Icons.people_alt_outlined,
                    iconBg: AppColors.adminGreenBg,
                    iconColor: AppColors.adminGreen,
                    trend: '${overview.activeCouples} total',
                    trendColor: AppColors.adminGreen,
                    value: overview.activeCouples.toString(),
                    label: 'Active couples',
                    onTap: () => context.go(AppRoutes.adminUsers),
                  ),
                  _KpiCard(
                    icon: Icons.list_alt_outlined,
                    iconBg: AppColors.adminIndigoBg,
                    iconColor: AppColors.adminIndigo,
                    trend: '${overview.pendingVendorsCount} pending',
                    trendColor: AppColors.adminGreen,
                    value: overview.registeredVendors.toString(),
                    label: 'Registered vendors',
                    onTap: () => context.go(AppRoutes.adminVendors),
                  ),
                  _KpiCard(
                    icon: Icons.verified_user_outlined,
                    iconBg: AppColors.adminAmberBg,
                    iconColor: AppColors.adminAmber,
                    trend: '${overview.pendingVendorsCount} pending',
                    trendColor: AppColors.amber,
                    value: '${overview.verificationRate}%',
                    label: 'Vendor verification rate',
                    onTap: () => context.go(AppRoutes.adminVendors),
                  ),
                  _KpiCard(
                    icon: Icons.credit_card_outlined,
                    iconBg: AppColors.adminBlueBg,
                    iconColor: AppColors.adminBlue,
                    trend: 'this week',
                    trendColor: AppColors.adminBlue,
                    value: overview.invitationsSentThisWeek.toString(),
                    label: 'Invitations sent',
                  ),
                ];

                if (wide) {
                  return Row(
                    children: [
                      for (int i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 14),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  );
                }

                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: cards,
                );
              },
            ),

            const SizedBox(height: 24),

            // ── Bottom panels ────────────────────────────────────
            LayoutBuilder(
              builder: (_, constraints) {
                final wide = constraints.maxWidth >= AppDimensions.tabletMin;
                final signups = _RecentSignupsPanel(
                  vendors: filteredVendors,
                  onViewAll: () => context.go(AppRoutes.adminVendors),
                );
                final queue = _VerificationQueuePanel(
                  vendors: filteredVendors,
                  onApprove: (id) async {
                    final vendor = pendingVendors.firstWhere((v) => v.id == id);
                    final token = ref.read(authProvider.notifier).accessToken;
                    if (token == null) return;
                    try {
                      await AdminApiService.instance.setVendorVerification(token, id, status: 'verified');
                      ref.invalidate(adminPendingVendorsProvider);
                      ref.invalidate(adminOverviewProvider);
                      if (context.mounted) {
                        showWedSnackBar(context, '${vendor.name} approved!', type: SnackType.success);
                      }
                    } on AdminApiException catch (e) {
                      if (context.mounted) showWedSnackBar(context, e.message, type: SnackType.error);
                    }
                  },
                  onReject: (id) async {
                    final vendor = pendingVendors.firstWhere((v) => v.id == id);
                    final token = ref.read(authProvider.notifier).accessToken;
                    if (token == null) return;
                    try {
                      await AdminApiService.instance.setVendorVerification(token, id, status: 'rejected');
                      ref.invalidate(adminPendingVendorsProvider);
                      ref.invalidate(adminOverviewProvider);
                      if (context.mounted) {
                        showWedSnackBar(context, '${vendor.name} rejected.', type: SnackType.error);
                      }
                    } on AdminApiException catch (e) {
                      if (context.mounted) showWedSnackBar(context, e.message, type: SnackType.error);
                    }
                  },
                );

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: signups),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: queue),
                    ],
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    signups,
                    const SizedBox(height: 20),
                    queue,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _VendorSearchDelegate(
        vendors: ref.read(adminPendingVendorsProvider).valueOrNull ?? [],
        onSelect: (_) => context.go(AppRoutes.adminVendors),
      ),
    );
  }
}

// ── Mobile search delegate ────────────────────────────────────────────────────

class _VendorSearchDelegate extends SearchDelegate<String> {
  final List<AdminVendor> vendors;
  final ValueChanged<String> onSelect;

  _VendorSearchDelegate({required this.vendors, required this.onSelect});

  @override
  String get searchFieldLabel => 'Search vendors...';

  List<AdminVendor> get _results {
    if (query.isEmpty) return vendors;
    final q = query.toLowerCase();
    return vendors
        .where((v) =>
            v.name.toLowerCase().contains(q) ||
            v.category.toLowerCase().contains(q) ||
            (v.location ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            tooltip: 'Clear search',
            icon: const Icon(Icons.clear),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final results = _results;
    if (results.isEmpty) {
      return Center(
        child: Text('No vendors found',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
      );
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, i) {
        final v = results[i];
        return ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _bgForCategory(v.category),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_iconForCategory(v.category),
                size: 18, color: _colorForCategory(v.category)),
          ),
          title: Text(v.name, style: AppTextStyles.bodySmall),
          subtitle: Text('${v.category} · ${v.location}',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
          onTap: () {
            close(context, v.id);
            onSelect(v.id);
          },
        );
      },
    );
  }
}

// ── KPI card ──────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String trend;
  final Color trendColor;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.trend,
    required this.trendColor,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const Spacer(),
                Text(
                  trend,
                  style: TextStyle(
                    color: trendColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: AppTextStyles.displaySmall.copyWith(
                color: AppColors.forestGreen,
                fontWeight: FontWeight.bold,
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        ),
        ),
      ),
    );
  }
}

// ── Flagged content banner ────────────────────────────────────────────────────

class _FlaggedContentBanner extends StatelessWidget {
  final int count;
  final VoidCallback onReview;

  const _FlaggedContentBanner({required this.count, required this.onReview});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.adminRedBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count flagged item${count == 1 ? '' : 's'} need${count == 1 ? 's' : ''} review',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onReview,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  'Review now',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.error,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent signups panel ──────────────────────────────────────────────────────

class _RecentSignupsPanel extends StatelessWidget {
  final List<AdminVendor> vendors;
  final VoidCallback onViewAll;

  const _RecentSignupsPanel({
    required this.vendors,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(
              children: [
                Text(
                  'Recent vendor signups',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: onViewAll,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text(
                        'View all',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Column headers
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text('Vendor',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Category',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Location',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3)),
                ),
                SizedBox(
                  width: 68,
                  child: Text('Status',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          if (vendors.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No recent signups',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint),
                ),
              ),
            )
          else
            ...vendors.asMap().entries.map((entry) {
              final i = entry.key;
              final v = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: _bgForCategory(v.category),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _iconForCategory(v.category),
                                  size: 15,
                                  color: _colorForCategory(v.category),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  v.name,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            v.category,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            v.location ?? '—',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(
                          width: 68,
                          child: _StatusBadge(status: 'pending'),
                        ),
                      ],
                    ),
                  ),
                  if (i < vendors.length - 1)
                    const Divider(height: 1, color: AppColors.divider),
                ],
              );
            }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Verification queue panel ──────────────────────────────────────────────────

class _VerificationQueuePanel extends StatelessWidget {
  final List<AdminVendor> vendors;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;

  const _VerificationQueuePanel({
    required this.vendors,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Text(
                  'Verification queue',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${vendors.length} pending',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Empty state
          if (vendors.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 44, color: AppColors.adminGreen),
                  const SizedBox(height: 10),
                  Text('All caught up!',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.forestGreen,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    'No vendors pending review.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...vendors.asMap().entries.map((entry) {
              final i = entry.key;
              final v = entry.value;
              return Column(
                children: [
                  if (i > 0)
                    const Divider(height: 1, color: AppColors.divider),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _bgForCategory(v.category),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _iconForCategory(v.category),
                            size: 18,
                            color: _colorForCategory(v.category),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.name,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${v.category} · ${fmtRelativeTime(v.submittedAt)}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: AppColors.adminGreenBg,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => onApprove(v.id),
                            child: const SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(Icons.check_rounded,
                                  size: 16, color: AppColors.adminGreen),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: AppColors.adminRedBg,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => onReject(v.id),
                            child: const SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(Icons.close_rounded,
                                  size: 16, color: AppColors.error),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;

    switch (status.toLowerCase()) {
      case 'verified':
        bg = AppColors.adminGreenBg;
        fg = AppColors.adminGreen;
        label = 'Verified';
      case 'pending':
        bg = AppColors.adminAmberBg;
        fg = AppColors.adminAmber;
        label = 'Pending';
      case 'flagged':
        bg = AppColors.adminRedBg;
        fg = AppColors.error;
        label = 'Flagged';
      default:
        bg = AppColors.adminNeutralBg;
        fg = AppColors.textSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
