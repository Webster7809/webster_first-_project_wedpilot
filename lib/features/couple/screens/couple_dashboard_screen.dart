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
    final budget = ref.watch(budgetProvider);
    final user = ref.watch(currentUserProvider);

    if (budget == null && couple?.hasBudget == true) {
      ref.read(budgetProvider.notifier).loadMockBudget(
            couple!.totalBudget!,
            couple.currency,
          );
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
                            color: Colors.white.withValues(alpha: 230)),
                      )
                    else
                      Text('Start planning your perfect wedding',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: Colors.white.withValues(alpha: 230))),
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
                  childAspectRatio: 0.9,
                  children: [
                    _QuickAction(emoji: '🔍', label: 'Find Vendors', onTap: () => context.go('/couple/vendors')),
                    _QuickAction(emoji: '💌', label: 'Invitations', onTap: () => context.push('/couple/invitations')),
                    _QuickAction(emoji: '✅', label: 'Checklist', onTap: () => context.push('/couple/checklist')),
                    _QuickAction(emoji: '❤️', label: 'Wishlist', onTap: () => context.push('/couple/wishlist')),
                    _QuickAction(emoji: '💬', label: 'Messages', onTap: () => context.go('/couple/messages')),
                    _QuickAction(emoji: '⭐', label: 'Reviews', onTap: () => context.push('/couple/reviews/new')),
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
                          color: AppColors.goldPremium.withValues(alpha: 26),
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
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.emoji, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 4)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
          ],
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
