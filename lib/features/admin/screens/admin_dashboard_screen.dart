import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/admin_provider.dart';

// ── Display-only data for "Recent vendor signups" panel ───────────────────────

class _SignupRow {
  final String name;
  final String category;
  final String location;
  final String status;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  const _SignupRow(this.name, this.category, this.location, this.status,
      this.icon, this.iconBg, this.iconColor);
}

const _kRecentSignups = [
  _SignupRow('Mukuba Gardens', 'Venue', 'Ndola', 'verified',
      Icons.apartment_outlined, Color(0xFFE4F3EC), AppColors.adminGreen),
  _SignupRow('Copperbelt Catering', 'Catering', 'Kitwe', 'pending',
      Icons.restaurant_outlined, Color(0xFFFEF0E7), AppColors.adminAmber),
  _SignupRow('Lumwana Decor', 'Decor & flowers', 'Ndola', 'verified',
      Icons.local_florist_outlined, Color(0xFFFCE4EC), AppColors.adminPink),
  _SignupRow('Zambezi Sounds DJ', 'DJ & MC', 'Lusaka', 'flagged',
      Icons.music_note_outlined, Color(0xFFE8EAF6), AppColors.adminIndigo),
];

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 600;

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
                  hintText: 'Search couples, vendors...',
                  hintStyle: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textHint, size: 18),
                  filled: true,
                  fillColor: Colors.white,
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
              icon: const Icon(Icons.search_rounded,
                  color: AppColors.textPrimary, size: 22),
              onPressed: () {},
            ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.textPrimary, size: 22),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFF2A9D8F),
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
            // KPI cards — 4 in a row on desktop, 2×2 on mobile
            LayoutBuilder(
              builder: (_, constraints) {
                final wide = constraints.maxWidth >= 600;
                final cards = [
                  _KpiCard(
                    icon: Icons.people_alt_outlined,
                    iconBg: AppColors.adminGreenBg,
                    iconColor: AppColors.adminGreen,
                    trend: '+12.4%',
                    trendColor: AppColors.adminGreen,
                    value: '2,418',
                    label: 'Active couples',
                  ),
                  _KpiCard(
                    icon: Icons.list_alt_outlined,
                    iconBg: AppColors.adminIndigoBg,
                    iconColor: AppColors.adminIndigo,
                    trend: '+8.1%',
                    trendColor: AppColors.adminGreen,
                    value: '643',
                    label: 'Registered vendors',
                  ),
                  _KpiCard(
                    icon: Icons.verified_user_outlined,
                    iconBg: AppColors.adminAmberBg,
                    iconColor: AppColors.adminAmber,
                    trend: '29 pending',
                    trendColor: AppColors.amber,
                    value: '94%',
                    label: 'Vendor verification rate',
                  ),
                  _KpiCard(
                    icon: Icons.credit_card_outlined,
                    iconBg: AppColors.adminBlueBg,
                    iconColor: AppColors.adminBlue,
                    trend: 'this week',
                    trendColor: AppColors.adminBlue,
                    value: '312',
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
                  childAspectRatio: 1.4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: cards,
                );
              },
            ),

            const SizedBox(height: 24),

            // Bottom panels — side by side on desktop, stacked on mobile
            LayoutBuilder(
              builder: (_, constraints) {
                final wide = constraints.maxWidth >= 600;
                final signups = const _RecentSignupsPanel();
                final queue = _VerificationQueuePanel(
                  vendors: adminState.pendingVendors,
                  onApprove: (id) =>
                      ref.read(adminProvider.notifier).approveVendor(id),
                  onReject: (id) =>
                      ref.read(adminProvider.notifier).rejectVendor(id),
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

  const _KpiCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.trend,
    required this.trendColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
    );
  }
}

// ── Recent signups panel ──────────────────────────────────────────────────────

class _RecentSignupsPanel extends StatelessWidget {
  const _RecentSignupsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'View all',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w600,
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
          // Data rows
          ..._kRecentSignups.asMap().entries.map((entry) {
            final i = entry.key;
            final row = entry.value;
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                                color: row.iconBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child:
                                  Icon(row.icon, size: 15, color: row.iconColor),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                row.name,
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
                          row.category,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          row.location,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(
                        width: 68,
                        child: _StatusBadge(status: row.status),
                      ),
                    ],
                  ),
                ),
                if (i < _kRecentSignups.length - 1)
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                  '29 pending',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Items
          ...vendors.asMap().entries.map((entry) {
            final i = entry.key;
            final v = entry.value;
            return Column(
              children: [
                if (i > 0) const Divider(height: 1, color: AppColors.divider),
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
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${v.category} · ${v.submitted}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => onApprove(v.id),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.adminGreenBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              size: 16, color: AppColors.adminGreen),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => onReject(v.id),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.adminRedBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: AppColors.error),
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
