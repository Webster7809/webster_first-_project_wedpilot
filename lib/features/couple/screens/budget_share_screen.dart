import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/state/resource.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/budget.dart';
import '../../../providers/budget_provider.dart';
import '../../../core/utils/format_utils.dart';

class BudgetShareScreen extends ConsumerWidget {
  const BudgetShareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(budgetProvider);

    if (!budgetState.hasData) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.forestGreen,
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.chevron_left_rounded,
                color: Colors.white, size: 28),
            onPressed: () => context.pop(),
          ),
          title: const Text('Budget Summary',
              style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: budgetState.status == ResourceStatus.loading
              ? const CircularProgressIndicator()
              : budgetState.hasError
                  ? Text(budgetState.errorMessage ?? 'Something went wrong.',
                      style: const TextStyle(color: AppColors.textSecondary))
                  : const Text('No budget set up yet.',
                      style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final budget = budgetState.data!;
    final categories = budget.categories;
    final bookedCount = categories.where((c) => c.spentAmount > 0).length;
    final pendingCount = categories.length - bookedCount;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.forestGreen,
            elevation: 0,
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.chevron_left_rounded,
                  color: Colors.white, size: 28),
              onPressed: () => context.pop(),
            ),
            expandedHeight: 130,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 44, 20, 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FINAL BUDGET SUMMARY',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.amber,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Share & export your plan',
                        style: AppTextStyles.displaySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // AI summary banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          color: AppColors.amber, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI-aligned across ${categories.length} vendor categories',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Matched to your ${budget.isAiGenerated ? 'AI-generated' : 'custom'} plan · budget optimised for your guest count and location.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withAlpha(178),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Budget summary card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 6,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fmtCurrency(budget.totalAllocated),
                              style: AppTextStyles.displaySmall.copyWith(
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 26,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'allocated of ${fmtCurrency(budget.totalAmount)} budget',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: budget.spendingPercentage
                                    .clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: AppColors.creamDark,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        AppColors.amber),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            fmtPercent(budget.spendingPercentage * 100),
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'OF BUDGET\nUSED',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Category breakdown header
                Row(
                  children: [
                    Text(
                      'Category breakdown',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$bookedCount spending · $pendingCount pending',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                ...categories.map((cat) => _CategoryBreakdownCard(cat: cat)),
              ]),
            ),
          ),
        ],
      ),

      // Fixed bottom bar
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  side:
                      const BorderSide(color: AppColors.divider, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.picture_as_pdf_outlined,
                    size: 18, color: Colors.white),
                label: const Text('Export as PDF',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category breakdown card ────────────────────────────────────────────────────

class _CategoryBreakdownCard extends StatelessWidget {
  final BudgetCategory cat;
  const _CategoryBreakdownCard({required this.cat});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.budgetCategoryColors[cat.categoryName] ??
        AppColors.forestGreen;
    final isActive = cat.spentAmount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 4,
              offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child:
                  Text(cat.categoryIcon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.categoryName,
                    style: AppTextStyles.titleMedium
                        .copyWith(color: AppColors.forestGreen)),
                Text(
                  isActive
                      ? 'Spent ${fmtCurrency(cat.spentAmount)} of ${fmtCurrency(cat.allocatedAmount)}'
                      : 'Allocated ${fmtCurrency(cat.allocatedAmount)}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.successBg
                  : AppColors.creamDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActive ? 'Active' : 'Pending',
              style: AppTextStyles.caption.copyWith(
                color: isActive
                    ? AppColors.budgetGreen
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
