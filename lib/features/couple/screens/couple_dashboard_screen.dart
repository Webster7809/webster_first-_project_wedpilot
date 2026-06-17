import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/inherited/shell_scaffold.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../widgets/wed_card.dart';
import '../../../widgets/wed_button.dart';

class CoupleDashboardScreen extends ConsumerWidget {
  const CoupleDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couple = ref.watch(coupleProfileProvider);
    final budgetState = ref.watch(budgetProvider);
    final budget = budgetState.budget;
    final user = ref.watch(currentUserProvider);

    if (couple?.hasBudget == true && budgetState.status == BudgetStatus.initial) {
      ref.read(budgetProvider.notifier).initializeBudgetForProfile(couple);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsible hero header
          SliverAppBar(
            expandedHeight: 170,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.secondary,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              tooltip: 'Open menu',
              onPressed: () =>
                  ShellScaffold.of(context)?.scaffoldKey.currentState?.openDrawer(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFF06292)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Hello, ${user?.name ?? 'Couple'} 👋',
                      style: AppTextStyles.headlineLarge.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    if (couple?.hasWeddingDate == true)
                      Text(
                        '${couple!.daysUntilWedding} days until your wedding! 🎊',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: Colors.white.withValues(alpha: 0.9)),
                      )
                    else
                      Text(
                        'Start planning your perfect wedding',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: Colors.white.withValues(alpha: 0.9)),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => context.push('/notifications'),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () => context.push('/settings'),
                tooltip: 'Settings',
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Summary Stats Row ──────────────────────────────
                _WeddingSummaryRow(couple: couple, budget: budget),
                const SizedBox(height: 20),

                // ── Budget Overview ────────────────────────────────
                if (budget != null) ...[
                  _SectionHeader(
                    title: 'Budget Overview',
                    actionLabel: 'See all',
                    onAction: () => context.go('/couple/budget'),
                  ),
                  const SizedBox(height: 12),
                  _BudgetDonutCard(budget: budget),
                  const SizedBox(height: 20),
                ] else ...[
                  WedCard(
                    child: Column(
                      children: [
                        const Text('💰', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        Text('Set Up Your Budget', style: AppTextStyles.headlineMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Let our AI allocate your budget across all wedding categories.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        WedButton(
                          label: 'Set Up Budget',
                          onPressed: () => context.push('/couple/budget/setup'),
                          width: 200,
                          height: 44,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Quick Actions ──────────────────────────────────
                _SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                  children: [
                    _QuickAction(
                      icon: Icons.storefront_rounded,
                      label: 'Find Vendors',
                      sublabel: 'Browse local pros',
                      gradient: const [Color(0xFFF06292), Color(0xFFF48FB1)],
                      onTap: () => context.go('/couple/vendors'),
                    ),
                    _QuickAction(
                      icon: Icons.mail_rounded,
                      label: 'Invitations',
                      sublabel: 'Design & send',
                      gradient: const [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
                      onTap: () => context.go('/couple/invitations'),
                    ),
                    _QuickAction(
                      icon: Icons.checklist_rounded,
                      label: 'Checklist',
                      sublabel: 'Track tasks',
                      gradient: const [Color(0xFF1976D2), Color(0xFF42A5F5)],
                      onTap: () => context.push('/couple/checklist'),
                    ),
                    _QuickAction(
                      icon: Icons.favorite_rounded,
                      label: 'Wishlist',
                      sublabel: 'Saved ideas',
                      gradient: const [Color(0xFFD81B60), Color(0xFFFF4081)],
                      onTap: () => context.push('/couple/wishlist'),
                    ),
                    _QuickAction(
                      icon: Icons.chat_bubble_rounded,
                      label: 'Messages',
                      sublabel: 'Chat vendors',
                      gradient: const [Color(0xFF00897B), Color(0xFF26C6DA)],
                      onTap: () => context.push('/couple/messages'),
                    ),
                    _QuickAction(
                      icon: Icons.star_rounded,
                      label: 'Reviews',
                      sublabel: 'Rate vendors',
                      gradient: const [Color(0xFFF57C00), Color(0xFFFFCA28)],
                      onTap: () => context.push('/couple/reviews/new'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Booked Vendors ─────────────────────────────────
                _SectionHeader(
                  title: 'Booked Vendors',
                  actionLabel: 'Find more',
                  onAction: () => context.go('/couple/vendors'),
                ),
                const SizedBox(height: 12),
                _BookedVendorsSection(),
                const SizedBox(height: 20),

                // ── AI Recommendations ─────────────────────────────
                _SectionHeader(
                  title: 'AI Picks For You',
                  actionLabel: 'Browse all',
                  onAction: () => context.go('/couple/vendors'),
                ),
                const SizedBox(height: 12),
                WedCard(
                  onTap: () => context.go('/couple/vendors'),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.goldPremium.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('🌟', style: TextStyle(fontSize: 24)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your matches are ready!',
                                style: AppTextStyles.titleMedium),
                            Text('6 vendors matched to your style & budget',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
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

// ── Wedding Summary Stats Row ──────────────────────────────────────────────────

class _WeddingSummaryRow extends ConsumerWidget {
  final dynamic couple;
  final dynamic budget;

  const _WeddingSummaryRow({required this.couple, required this.budget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskProvider);
    final taskProgress = tasks.isEmpty
        ? 0.0
        : tasks.where((t) => t.isCompleted).length / tasks.length;

    final days = couple?.hasWeddingDate == true
        ? '${couple!.daysUntilWedding}'
        : '--';
    final guests = couple?.guestCount != null
        ? '${couple!.guestCount}'
        : '--';
    final budgetRatio = (budget != null && budget.totalAmount > 0)
        ? (budget.totalSpent / budget.totalAmount).clamp(0.0, 1.0)
        : null;
    final budgetPct = budgetRatio != null
        ? '${(budgetRatio * 100).toStringAsFixed(0)}%'
        : '--';
    final taskPct = '${(taskProgress * 100).round()}%';

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.calendar_today_rounded,
            value: days,
            label: 'Days Left',
            color: AppColors.secondary,
            subtitle: couple?.hasWeddingDate == true ? 'to go!' : 'Set date',
            onTap: () => context.go('/couple/profile'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.people_rounded,
            value: guests,
            label: 'Guests',
            color: AppColors.info,
            subtitle: 'invited',
            onTap: () => context.go('/couple/invitations'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.account_balance_wallet_rounded,
            value: budgetPct,
            label: 'Budget Used',
            color: AppColors.warning,
            progress: budgetRatio,
            onTap: () => context.go('/couple/budget'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.checklist_rounded,
            value: taskPct,
            label: 'Tasks Done',
            color: AppColors.success,
            progress: taskProgress,
            onTap: () => context.push('/couple/checklist'),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String? subtitle;
  final Color color;
  final double? progress;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.subtitle,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(28),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withAlpha(24),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && progress == null) ...[
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 9,
                      color: color.withAlpha(180),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (progress != null) ...[
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: color.withAlpha(30),
                      color: color,
                      minHeight: 3,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 9,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 8, color: color),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Booked Vendors Section ─────────────────────────────────────────────────────

class _BookedVendorsSection extends StatelessWidget {
  const _BookedVendorsSection();

  static const _mockBookings = [
    _BookingData(
      emoji: '📸',
      name: 'Blossom Photography',
      category: 'Photography',
      status: 'Confirmed',
      statusColor: AppColors.success,
      date: 'Jun 14, 2027',
    ),
    _BookingData(
      emoji: '🌸',
      name: 'Petal & Bloom Florals',
      category: 'Floristry',
      status: 'Confirmed',
      statusColor: AppColors.success,
      date: 'Jun 14, 2027',
    ),
    _BookingData(
      emoji: '🎵',
      name: 'Harmony Live Band',
      category: 'Music',
      status: 'Pending',
      statusColor: AppColors.warning,
      date: 'Jun 14, 2027',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_mockBookings.isEmpty) {
      return WedCard(
        child: Column(
          children: [
            const Text('🔍', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text('No vendors booked yet', style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            Text('Search and book verified wedding vendors',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            WedButton(
              label: 'Search Vendors',
              onPressed: () => context.go('/couple/vendors'),
              width: 180,
              height: 40,
            ),
          ],
        ),
      );
    }

    return Column(
      children: _mockBookings.map((b) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _BookedVendorTile(booking: b),
      )).toList(),
    );
  }
}

class _BookingData {
  final String emoji;
  final String name;
  final String category;
  final String status;
  final Color statusColor;
  final String date;

  const _BookingData({
    required this.emoji,
    required this.name,
    required this.category,
    required this.status,
    required this.statusColor,
    required this.date,
  });
}

class _BookedVendorTile extends StatelessWidget {
  final _BookingData booking;
  const _BookedVendorTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: cs.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(booking.emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.name, style: AppTextStyles.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${booking.category} · ${booking.date}',
                  style: AppTextStyles.caption.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: booking.statusColor.withAlpha(26),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              booking.status,
              style: AppTextStyles.caption.copyWith(
                color: booking.statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Section Header ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.headlineSmall),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.secondary),
            ),
          ),
      ],
    );
  }
}

// ── Quick Action Tile ─────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: AppTextStyles.labelLarge.copyWith(fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    color: onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
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

// ── Budget Donut Card ──────────────────────────────────────────────────────────

class _BudgetDonutCard extends StatelessWidget {
  final dynamic budget;
  const _BudgetDonutCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    return WedCard(
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: [
                  PieChartSectionData(
                    value: budget.totalSpent,
                    color: AppColors.secondary,
                    radius: 20,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: (budget.totalAmount - budget.totalSpent)
                        .clamp(0, double.infinity),
                    color: AppColors.primary,
                    radius: 20,
                    showTitle: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Budget', style: AppTextStyles.labelMedium),
                Text(
                  '\$${budget.totalAmount.toStringAsFixed(0)}',
                  style: AppTextStyles.headlineLarge
                      .copyWith(color: AppColors.secondary),
                ),
                const SizedBox(height: 8),
                _BudgetLegend(
                  color: AppColors.secondary,
                  label: 'Spent',
                  value: '\$${budget.totalSpent.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 4),
                _BudgetLegend(
                  color: AppColors.primary,
                  label: 'Remaining',
                  value: '\$${budget.remainingBudget.toStringAsFixed(0)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _BudgetLegend(
      {required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label: ', style: AppTextStyles.caption.copyWith(color: secondary)),
        Text(value,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: secondary,
            )),
      ],
    );
  }
}
