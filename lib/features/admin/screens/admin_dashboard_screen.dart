import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/wed_card.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Admin header
          SliverAppBar(
            expandedHeight: 130,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.neutralDark,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF283593)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shield_rounded,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'ADMIN',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Platform Dashboard',
                      style: AppTextStyles.headlineLarge
                          .copyWith(color: Colors.white),
                    ),
                    Text(
                      'Wedpilot Administration',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Platform KPIs ──────────────────────────────────
                Text('Platform Overview', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: const [
                    _KpiCard(
                      title: 'Total Users',
                      value: '1,284',
                      icon: Icons.people_rounded,
                      color: AppColors.info,
                      change: '+47 today',
                      changePositive: true,
                    ),
                    _KpiCard(
                      title: 'Total Couples',
                      value: '847',
                      icon: Icons.favorite_rounded,
                      color: AppColors.secondary,
                      change: '+12 this week',
                      changePositive: true,
                    ),
                    _KpiCard(
                      title: 'Total Vendors',
                      value: '326',
                      icon: Icons.storefront_rounded,
                      color: AppColors.tertiary,
                      change: '12 pending approval',
                      changePositive: false,
                    ),
                    _KpiCard(
                      title: 'Total Bookings',
                      value: '4,218',
                      icon: Icons.calendar_month_rounded,
                      color: AppColors.goldPremium,
                      change: '+89 this month',
                      changePositive: true,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Revenue Strip ──────────────────────────────────
                _RevenueStrip(),
                const SizedBox(height: 20),

                // ── Management Actions ─────────────────────────────
                Text('Management', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 12),
                _AdminActionCard(
                  icon: Icons.verified_user_rounded,
                  emoji: '✅',
                  title: 'Vendor Approval',
                  subtitle: '12 vendors awaiting review',
                  badge: '12',
                  badgeColor: AppColors.warning,
                  onTap: () => context.go('/admin/vendors'),
                ),
                const SizedBox(height: 10),
                _AdminActionCard(
                  icon: Icons.manage_accounts_rounded,
                  emoji: '👥',
                  title: 'User Management',
                  subtitle: 'View, edit, and suspend platform users',
                  onTap: () => context.push('/admin/users'),
                ),
                const SizedBox(height: 10),
                _AdminActionCard(
                  icon: Icons.bar_chart_rounded,
                  emoji: '📊',
                  title: 'Reports & Analytics',
                  subtitle: 'Revenue, growth, and engagement insights',
                  onTap: () => context.push('/admin/analytics'),
                ),
                const SizedBox(height: 10),
                _AdminActionCard(
                  icon: Icons.shield_outlined,
                  emoji: '🛡️',
                  title: 'Content Moderation',
                  subtitle: '8 items flagged for review',
                  badge: '8',
                  badgeColor: AppColors.error,
                  onTap: () => context.push('/admin/moderation'),
                ),
                const SizedBox(height: 20),

                // ── System Health ──────────────────────────────────
                Text('System Health', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 12),
                WedCard(
                  child: Column(
                    children: const [
                      _HealthRow(
                        label: 'API Response Time (p95)',
                        value: '280 ms',
                        status: 'good',
                      ),
                      Divider(height: 16),
                      _HealthRow(
                        label: 'Database Query Time',
                        value: '45 ms',
                        status: 'good',
                      ),
                      Divider(height: 16),
                      _HealthRow(
                        label: 'Error Rate',
                        value: '0.02%',
                        status: 'good',
                      ),
                      Divider(height: 16),
                      _HealthRow(
                        label: 'Uptime (30 days)',
                        value: '99.98%',
                        status: 'good',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Revenue Strip ──────────────────────────────────────────────────────────────

class _RevenueStrip extends StatelessWidget {
  const _RevenueStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Revenue',
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$8,420',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.trending_up_rounded,
                        color: Colors.greenAccent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '+23% vs last month',
                      style: AppTextStyles.caption
                          .copyWith(color: Colors.greenAccent),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, height: 60, color: Colors.white24),
          Expanded(
            child: Column(
              children: [
                _RevMetric(label: 'Active Subs', value: '184'),
                const SizedBox(height: 8),
                _RevMetric(label: 'Avg. LTV', value: '\$45.7'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RevMetric extends StatelessWidget {
  final String label;
  final String value;
  const _RevMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.headlineMedium
                .copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
        Text(label,
            style:
                AppTextStyles.caption.copyWith(color: Colors.white60)),
      ],
    );
  }
}

// ── KPI Card ───────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String change;
  final bool changePositive;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.change,
    required this.changePositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Icon(Icons.more_horiz_rounded,
                  size: 16, color: AppColors.textHint),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(title,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                changePositive
                    ? Icons.arrow_upward_rounded
                    : Icons.warning_amber_rounded,
                size: 11,
                color: changePositive ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  change,
                  style: AppTextStyles.caption.copyWith(
                    color:
                        changePositive ? AppColors.success : AppColors.warning,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Admin Action Card ──────────────────────────────────────────────────────────

class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String emoji;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.icon,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return WedCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppColors.warning),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          const Icon(Icons.arrow_forward_ios,
              size: 14, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

// ── Health Row ─────────────────────────────────────────────────────────────────

class _HealthRow extends StatelessWidget {
  final String label;
  final String value;
  final String status;

  const _HealthRow(
      {required this.label, required this.value, required this.status});

  @override
  Widget build(BuildContext context) {
    final isGood = status == 'good';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Row(
          children: [
            Text(value, style: AppTextStyles.titleMedium),
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isGood ? AppColors.success : AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
