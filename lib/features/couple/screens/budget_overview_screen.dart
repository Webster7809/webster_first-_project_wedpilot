import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/inherited/shell_scaffold.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/budget.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/vendor_provider.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_card.dart';

class BudgetOverviewScreen extends ConsumerWidget {
  const BudgetOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(budgetProvider);
    final budget = budgetState.budget;
    final selectedServices = ref.watch(selectedServiceCategoriesProvider);
    final recommendations = ref.watch(recommendedVendorsProvider);
    final wishlist = ref.watch(wishlistProvider);

    if (budget == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Budget'),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Open menu',
              onPressed: () =>
                  ShellScaffold.of(ctx)?.scaffoldKey.currentState?.openDrawer(),
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('💰', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 16),
              Text('No budget set up yet', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              Text('Use AI to allocate your budget across all categories',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
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
      appBar: AppBar(
        title: const Text('Budget Overview'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Open menu',
            onPressed: () =>
                ShellScaffold.of(ctx)?.scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/couple/budget/expense/new'),
            tooltip: 'Add Expense',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () => context.push('/couple/reports'),
            tooltip: 'View Reports',
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _exportBudgetPdf(context, budget, recommendations),
            tooltip: 'Export PDF',
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
                colors: [AppColors.secondary, AppColors.secondary.withValues(alpha: 0.7)],
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
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
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
          const SizedBox(height: 20),
          if (recommendations.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('AI Recommended Vendors', style: AppTextStyles.headlineSmall),
                if (selectedServices.isNotEmpty)
                  Text('${selectedServices.length} categories',
                      style: AppTextStyles.caption.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      )),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recommendations.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, index) {
                  final vendor = recommendations[index];
                  return SizedBox(
                    width: 240,
                    child: VendorCard(
                      vendor: vendor,
                      isWishlisted: wishlist.contains(vendor.id),
                      rank: index + 1,
                      onTap: () => context.push('/couple/vendors/${vendor.id}'),
                      onWishlistToggle: () => ref.read(wishlistProvider.notifier).toggle(vendor.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCategoryDetails(BuildContext context, dynamic cat) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
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
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
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

  Future<void> _exportBudgetPdf(BuildContext context, Budget budget, List<dynamic> recommendations) async {
    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return [
          pw.Header(level: 0, text: 'Wedding Budget Report'),
          pw.Paragraph(text: 'Total budget: ${budget.currency} ${budget.totalAmount.toStringAsFixed(0)}'),
          pw.Paragraph(text: 'Remaining budget: ${budget.currency} ${budget.remainingBudget.toStringAsFixed(0)}'),
          pw.SizedBox(height: 12),
          pw.Header(level: 1, text: 'Budget Breakdown'),
          pw.TableHelper.fromTextArray(
            headers: ['Category', 'Allocated', 'Spent'],
            data: budget.categories
                .map((cat) => [
                      cat.categoryName,
                      '${budget.currency} ${cat.allocatedAmount.toStringAsFixed(0)}',
                      '${budget.currency} ${cat.spentAmount.toStringAsFixed(0)}',
                    ])
                .toList(),
          ),
          if (budget.customItems.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Header(level: 1, text: 'Custom Items'),
            pw.TableHelper.fromTextArray(
              headers: ['Item', 'Estimated Cost'],
              data: budget.customItems
                  .map((item) => [item.name, '${budget.currency} ${item.amount.toStringAsFixed(0)}'])
                  .toList(),
            ),
          ],
          if (recommendations.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Header(level: 1, text: 'AI Vendor Recommendations'),
            pw.Column(
              children: recommendations.map((vendor) {
                return pw.Bullet(
                  text: '${vendor.businessName} • ${vendor.category} • from ${budget.currency} ${vendor.priceMin.toStringAsFixed(0)}',
                );
              }).toList(),
            ),
          ],
        ];
      },
    ));

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'wedpilot-budget-report.pdf');
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
        Text(label, style: AppTextStyles.caption.copyWith(color: color.withValues(alpha: 0.8))),
      ],
    );
  }
}
