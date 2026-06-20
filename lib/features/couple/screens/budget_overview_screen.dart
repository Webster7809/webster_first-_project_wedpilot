import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/budget.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/vendor_provider.dart';
import '../../../widgets/wed_button.dart';

class BudgetOverviewScreen extends ConsumerWidget {
  const BudgetOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetState = ref.watch(budgetProvider);
    final budget = budgetState.budget;
    final recommendations = ref.watch(recommendedVendorsProvider);

    if (budget == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.forestGreen,
          automaticallyImplyLeading: false,
          title: const Text('Budget', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  size: 64, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text('No budget set up yet',
                  style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Use AI to allocate your budget across all categories',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
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
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // ── Dark green header ──────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.forestGreen,
            elevation: 0,
            expandedHeight: 100,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => context.push('/couple/budget/expense/new'),
                tooltip: 'Add Expense',
              ),
              IconButton(
                icon: const Icon(Icons.file_download_outlined,
                    color: Colors.white),
                onPressed: () =>
                    _exportBudgetPdf(context, budget, recommendations),
                tooltip: 'Export PDF',
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'YOUR WEDDING BUDGET',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.amber,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Budget tracker',
                        style: AppTextStyles.headlineMedium.copyWith(
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

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 48),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Donut summary ────────────────────────────────────────────
                _DonutSummaryCard(budget: budget),
                const SizedBox(height: 24),

                // ── Spending by category ─────────────────────────────────────
                Text('Spending by category',
                    style: AppTextStyles.headlineSmall
                        .copyWith(color: AppColors.forestGreen)),
                const SizedBox(height: 12),
                ...budget.categories.map((cat) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CategoryRow(
                        cat: cat,
                        total: budget.totalAmount,
                      ),
                    )),
                const SizedBox(height: 24),

                // ── Recent payments ──────────────────────────────────────────
                Text('Recent payments',
                    style: AppTextStyles.headlineSmall
                        .copyWith(color: AppColors.forestGreen)),
                const SizedBox(height: 12),
                ..._buildRecentPayments(budget),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecentPayments(Budget budget) {
    final expenses = budget.expenses;
    if (expenses.isEmpty) {
      return [
        const _RecentPaymentCard(
          icon: '🏛️',
          title: 'Mukuba Gardens — deposit',
          date: '14 June 2026',
          amount: 'ZMW 10,000',
        ),
        const SizedBox(height: 10),
        const _RecentPaymentCard(
          icon: '🍽️',
          title: 'Zesco Catering Co. — booking fee',
          date: '10 June 2026',
          amount: 'ZMW 5,300',
        ),
      ];
    }
    return expenses.take(5).map((e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _RecentPaymentCard(
          icon: '💳',
          title: '${e.vendorName ?? e.categoryName} — ${e.description}',
          date: _formatDate(e.createdAt),
          amount: 'ZMW ${e.amount.toStringAsFixed(0)}',
        ),
      );
    }).toList();
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  Future<void> _exportBudgetPdf(
      BuildContext context, Budget budget, List<dynamic> recommendations) async {
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => [
        pw.Header(level: 0, text: 'Wedding Budget Report'),
        pw.Paragraph(
            text:
                'Total budget: ${budget.currency} ${budget.totalAmount.toStringAsFixed(0)}'),
        pw.Paragraph(
            text:
                'Remaining: ${budget.currency} ${budget.remainingBudget.toStringAsFixed(0)}'),
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
      ],
    ));
    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'wedpilot-budget.pdf');
  }
}

// ── Donut summary card ─────────────────────────────────────────────────────────

class _DonutSummaryCard extends StatelessWidget {
  final Budget budget;
  const _DonutSummaryCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    final spent = budget.totalSpent;
    final total = budget.totalAmount;
    final remaining = budget.remainingBudget;
    final isOver = remaining < 0;

    final spentVal = spent.clamp(0.0, total);
    final remainVal = (total - spentVal).clamp(0.0, total);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withAlpha(15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Donut chart
          SizedBox(
            width: 110,
            height: 110,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 34,
                startDegreeOffset: -90,
                sections: [
                  PieChartSectionData(
                    value: spentVal > 0 ? spentVal : 0.001,
                    color: AppColors.amber,
                    radius: 20,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: remainVal > 0 ? remainVal : 0.001,
                    color: const Color(0xFFE0DDD6),
                    radius: 20,
                    showTitle: false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Text summary
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ZMW ${_fmt(spent)}',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
                Text(
                  'spent of ZMW ${_fmt(total)} budget',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      isOver
                          ? Icons.trending_down_rounded
                          : Icons.trending_up_rounded,
                      size: 15,
                      color: isOver ? AppColors.error : AppColors.forestGreen,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'ZMW ${_fmt(remaining.abs())} ${isOver ? 'over budget' : 'remaining'}',
                        style: AppTextStyles.caption.copyWith(
                          color: isOver
                              ? AppColors.error
                              : AppColors.forestGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000) {
      final s = v.toStringAsFixed(0);
      final buf = StringBuffer();
      int count = 0;
      for (int i = s.length - 1; i >= 0; i--) {
        if (count > 0 && count % 3 == 0) buf.write(',');
        buf.write(s[i]);
        count++;
      }
      return buf.toString().split('').reversed.join();
    }
    return v.toStringAsFixed(0);
  }
}

// ── Category row ───────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final BudgetCategory cat;
  final double total;

  const _CategoryRow({required this.cat, required this.total});

  static const _catColors = <String, Color>{
    'Venue': Color(0xFFC9892B),
    'Catering': Color(0xFFD4A017),
    'Photography': Color(0xFF4A8B6F),
    'Decor & flowers': AppColors.forestGreen,
    'DJ & MC': Color(0xFF6B9E8A),
    'Transport': Color(0xFF8BAE9E),
    'Wedding attire': Color(0xFF7B8E7A),
    'Cake & sweets': Color(0xFFB5916A),
  };

  static const _catVendors = <String, String>{
    'Venue': 'Mukuba Gardens',
    'Catering': 'Zesco Catering Co.',
    'Decor & flowers': 'Lumwana Decor & Blooms',
    'Photography': 'Lumino Photography',
    'DJ & MC': 'Zambezi Sounds DJ',
    'Transport': 'Not yet booked',
    'Wedding attire': 'Not yet booked',
    'Cake & sweets': 'Sweet Dreams Bakery',
  };

  @override
  Widget build(BuildContext context) {
    final spent = cat.spentAmount;
    final allocated = cat.allocatedAmount;
    final pct = total > 0 ? (spent / total * 100).round() : 0;
    final barFill =
        allocated > 0 ? (spent / allocated).clamp(0.0, 1.0) : 0.0;
    final color = _catColors[cat.categoryName] ?? AppColors.forestGreen;
    final vendorName = _catVendors[cat.categoryName] ?? 'Not yet booked';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(cat.categoryIcon,
                      style: const TextStyle(fontSize: 18)),
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
                    Text(vendorName,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'ZMW ${spent.toStringAsFixed(0)}',
                    style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.forestGreen),
                  ),
                  Text(
                    '$pct% of budget',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: barFill,
              backgroundColor: const Color(0xFFEEEBE4),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent payment card ────────────────────────────────────────────────────────

class _RecentPaymentCard extends StatelessWidget {
  final String icon;
  final String title;
  final String date;
  final String amount;

  const _RecentPaymentCard({
    required this.icon,
    required this.title,
    required this.date,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.titleMedium
                        .copyWith(color: AppColors.forestGreen),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(date,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.forestGreen,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
