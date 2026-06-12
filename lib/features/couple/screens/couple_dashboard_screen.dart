import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/budget_provider.dart';
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
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.secondary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.secondary,
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
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withValues(alpha: 0.9)),
                      )
                    else
                      Text('Start planning your perfect wedding',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: Colors.white.withValues(alpha: 0.9))),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => context.push('/notifications'),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Budget overview
                if (budget != null) ...[
                  _SectionHeader(
                    title: 'Budget Overview',
                    actionLabel: 'See all',
                    onAction: () => context.push('/couple/budget'),
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
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
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

                // Quick actions
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
                      gradient: const [Color(0xFFC2185B), Color(0xFFE91E8C)],
                      onTap: () => context.go('/couple/vendors'),
                    ),
                    _QuickAction(
                      icon: Icons.mail_rounded,
                      label: 'Invitations',
                      sublabel: 'Design & send',
                      gradient: const [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
                      onTap: () => context.push('/couple/invitations'),
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
                      onTap: () => context.go('/couple/messages'),
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

                // AI Recommendations
                _SectionHeader(
                  title: 'AI Picks For You',
                  actionLabel: 'Browse all',
                  onAction: () => context.go('/couple/vendors'),
                ),
                const SizedBox(height: 12),
                WedCard(
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.goldPremium.withAlpha(26),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('🌟', style: TextStyle(fontSize: 24))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Your matches are ready!', style: AppTextStyles.titleMedium),
                            Text('6 vendors matched to your style & budget',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                    ],
                  ),
                  onTap: () => context.go('/couple/vendors'),
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
            child: Text(actionLabel!, style: AppTextStyles.labelMedium.copyWith(color: AppColors.secondary)),
          ),
      ],
    );
  }
}

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
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
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
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
                    value: (budget.totalAmount - budget.totalSpent).clamp(0, double.infinity),
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
                Text('\$${budget.totalAmount.toStringAsFixed(0)}',
                    style: AppTextStyles.headlineLarge.copyWith(color: AppColors.secondary)),
                const SizedBox(height: 8),
                _BudgetLegend(color: AppColors.secondary, label: 'Spent',
                    value: '\$${budget.totalSpent.toStringAsFixed(0)}'),
                const SizedBox(height: 4),
                _BudgetLegend(color: AppColors.primary, label: 'Remaining',
                    value: '\$${budget.remainingBudget.toStringAsFixed(0)}'),
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
  const _BudgetLegend({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: ', style: AppTextStyles.caption),
        Text(value, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
