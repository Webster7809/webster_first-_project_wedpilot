import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_card.dart';

class BudgetOverviewScreen extends ConsumerWidget {
  const BudgetOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(budgetProvider);
    final couple = ref.watch(coupleProfileProvider);

    if (budget == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Budget')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💰', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              Text('No budget set up yet', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              Text('Use AI to allocate your budget across all categories',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              WedButton(
                label: 'Set Up Budget',
                onPressed: () => context.push('/couple/budget/setup'),
                width: 200,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Budget Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/couple/budget/expense/new'),
            tooltip: 'Add Expense',
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {},
            tooltip: 'Export',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.secondary, AppColors.secondary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Budget', style: AppTextStyles.labelMedium.copyWith(color: Colors.white70)),
                const SizedBox(height: 4),
                Text('\$${budget.totalAmount.toStringAsFixed(0)}',
                    style: AppTextStyles.displayMedium.copyWith(color: Colors.white)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryItem(
                        label: 'Spent',
                        value: '\$${budget.totalSpent.toStringAsFixed(0)}',
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: _SummaryItem(
                        label: 'Remaining',
                        value: '\$${budget.remainingBudget.toStringAsFixed(0)}',
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: _SummaryItem(
                        label: 'Used',
                        value: '${budget.spendingPercentage.toStringAsFixed(0)}%',
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: budget.spendingPercentage / 100,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Categories', style: AppTextStyles.headlineSmall),
              TextButton.icon(
                onPressed: () => context.push('/couple/budget/expense/new'),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Expense'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ...budget.categories.map((cat) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BudgetCategoryCard(
                  categoryName: cat.categoryName,
                  categoryIcon: cat.categoryIcon,
                  allocated: cat.allocatedAmount,
                  spent: cat.spentAmount,
                  currency: budget.currency,
                  onTap: () => _showCategoryDetails(context, cat),
                ),
              )),
        ],
      ),
    );
  }

  void _showCategoryDetails(BuildContext context, dynamic cat) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(cat.categoryIcon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Text(cat.categoryName, style: AppTextStyles.headlineMedium),
              ],
            ),
            const SizedBox(height: 16),
            if (cat.aiJustification != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.info.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome, size: 16, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(cat.aiJustification!,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.info))),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.headlineSmall.copyWith(color: color)),
        Text(label, style: AppTextStyles.caption.copyWith(color: color.withOpacity(0.8))),
      ],
    );
  }
}
