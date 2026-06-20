import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/wed_card.dart';
import '../../../widgets/section_header.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _alertDismissed = false;

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will be returned to the login screen.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Sign out',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  String _alertMessage(AdminState s) {
    final parts = <String>[];
    if (s.pendingVendors.isNotEmpty) {
      parts.add('${s.pendingVendors.length} vendors pending approval');
    }
    if (s.totalFlaggedItems > 0) {
      parts.add('${s.totalFlaggedItems} items flagged');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    final hasAlerts = adminState.pendingVendors.isNotEmpty ||
        adminState.totalFlaggedItems > 0;

    return Scaffold(
      backgroundColor: AppColors.adminPage,
      body: CustomScrollView(
        slivers: [
            // ── Sticky Header ────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: AppColors.adminPage,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 1,
              automaticallyImplyLeading: false,
              toolbarHeight: 72,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    greeting,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Admin',
                    style: AppTextStyles.displayMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              actions: [
                _CircleBtn(icon: Icons.notifications_outlined, onTap: () {}),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _confirmLogout,
                  child: const _AdminAvatar(),
                ),
                const SizedBox(width: 16),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Alert Banner ──────────────────────────────────
                  if (!_alertDismissed && hasAlerts) ...[
                    _AlertBanner(
                      message: _alertMessage(adminState),
                      onReview: () => context.go('/admin/vendors'),
                      onDismiss: () => setState(() => _alertDismissed = true),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── KPI Cards ─────────────────────────────────────
                  Row(
                    children: const [
                      Expanded(
                        child: _StatCard(
                          label: 'Couples',
                          value: '2,847',
                          icon: Icons.people_alt_outlined,
                          iconColor: AppColors.adminGreen,
                          iconBg: AppColors.adminGreenBg,
                          trend: '+12.4%',
                          trendUp: true,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Vendors',
                          value: '456',
                          icon: Icons.storefront_outlined,
                          iconColor: AppColors.adminIndigo,
                          iconBg: AppColors.adminIndigoBg,
                          trend: '+8.1%',
                          trendUp: true,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Revenue',
                          value: 'ZMW 24.5K',
                          icon: Icons.payments_outlined,
                          iconColor: AppColors.adminAmber,
                          iconBg: AppColors.adminAmberBg,
                          trend: '+23%',
                          trendUp: true,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Active',
                          value: '1,203',
                          icon: Icons.show_chart_rounded,
                          iconColor: AppColors.adminPink,
                          iconBg: AppColors.adminPinkBg,
                          trend: '-2.1%',
                          trendUp: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Management ────────────────────────────────────
                  const SectionHeader(title: 'Management'),
                  const SizedBox(height: 12),
                  _ActionTile(
                    icon: Icons.verified_user_rounded,
                    iconColor: AppColors.adminAmber,
                    iconBg: AppColors.adminAmberBg,
                    title: 'Vendor Approval',
                    subtitle: adminState.pendingVendors.isEmpty
                        ? 'No vendors pending review'
                        : '${adminState.pendingVendors.length} vendors awaiting review',
                    badge: adminState.pendingVendors.isNotEmpty
                        ? '${adminState.pendingVendors.length}'
                        : null,
                    badgeColor: AppColors.adminAmber,
                    onTap: () => context.go('/admin/vendors'),
                  ),
                  const SizedBox(height: 8),
                  _ActionTile(
                    icon: Icons.manage_accounts_rounded,
                    iconColor: AppColors.adminIndigo,
                    iconBg: AppColors.adminIndigoBg,
                    title: 'User Management',
                    subtitle:
                        'View, edit, and suspend users',
                    onTap: () => context.push('/admin/users'),
                  ),
                  const SizedBox(height: 8),
                  _ActionTile(
                    icon: Icons.bar_chart_rounded,
                    iconColor: AppColors.adminBlue,
                    iconBg: AppColors.adminBlueBg,
                    title: 'Reports & Analytics',
                    subtitle: 'Revenue, growth, and engagement',
                    onTap: () => context.push('/admin/analytics'),
                  ),
                  const SizedBox(height: 8),
                  _ActionTile(
                    icon: Icons.shield_outlined,
                    iconColor: AppColors.error,
                    iconBg: AppColors.adminRedBg,
                    title: 'Content Moderation',
                    subtitle: adminState.totalFlaggedItems == 0
                        ? 'No items flagged'
                        : '${adminState.totalFlaggedItems} items flagged for review',
                    badge: adminState.totalFlaggedItems > 0
                        ? '${adminState.totalFlaggedItems}'
                        : null,
                    badgeColor: AppColors.error,
                    onTap: () => context.push('/admin/moderation'),
                  ),
                  const SizedBox(height: 28),

                  // ── System Health ─────────────────────────────────
                  const SectionHeader(title: 'System Health'),
                  const SizedBox(height: 12),
                  WedCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        _HealthRow(
                            label: 'API Response Time (p95)',
                            value: '280 ms',
                            good: true),
                        Divider(height: 24, color: AppColors.adminNeutralBg),
                        _HealthRow(
                            label: 'Database Query Time',
                            value: '45 ms',
                            good: true),
                        Divider(height: 24, color: AppColors.adminNeutralBg),
                        _HealthRow(
                            label: 'Error Rate', value: '0.02%', good: true),
                        Divider(height: 24, color: AppColors.adminNeutralBg),
                        _HealthRow(
                            label: 'Uptime (30 days)',
                            value: '99.98%',
                            good: true),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
    );
  }
}

// ── Admin Avatar ──────────────────────────────────────────────────────────────

class _AdminAvatar extends StatelessWidget {
  const _AdminAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: AppColors.adminIndigo,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'A',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// ── Alert Banner ──────────────────────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  final String message;
  final VoidCallback onReview;
  final VoidCallback onDismiss;

  const _AlertBanner({
    required this.message,
    required this.onReview,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.adminAmberBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminAmber.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.adminAmber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onReview,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.adminAmber,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Review',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.adminAmber, fontWeight: FontWeight.w700),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close_rounded,
                size: 16, color: AppColors.adminAmber),
          ),
        ],
      ),
    );
  }
}

// ── Circle Button ─────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String trend;
  final bool trendUp;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.trend,
    required this.trendUp,
  });

  @override
  Widget build(BuildContext context) {
    final trendColor = trendUp ? AppColors.success : AppColors.error;
    return Container(
      decoration: BoxDecoration(
        color: iconColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: iconColor.withAlpha(50),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 3),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [iconBg, Colors.white],
            stops: const [0.0, 0.7],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(22),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.0,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: BoxDecoration(
                color: trendColor.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    trendUp
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 8,
                    color: trendColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    trend,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: trendColor,
                    ),
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

// ── Action Tile ───────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.chevron_right_rounded,
                    size: 20, color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Health Row ────────────────────────────────────────────────────────────────

class _HealthRow extends StatelessWidget {
  final String label;
  final String value;
  final bool good;

  const _HealthRow(
      {required this.label, required this.value, required this.good});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: good ? AppColors.success : AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
