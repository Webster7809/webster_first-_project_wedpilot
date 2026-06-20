import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/report_provider.dart';
import '../../../providers/task_provider.dart' show TaskReportData;

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    // Auto-generate all reports when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportProvider.notifier).generateAll();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Regenerate all reports',
            onPressed: () =>
                ref.read(reportProvider.notifier).generateAll(),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Budget'),
            Tab(text: 'RSVP'),
            Tab(text: 'Vendors'),
            Tab(text: 'Tasks'),
          ],
        ),
      ),
      body: reportState.isGenerating
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _BudgetReportTab(report: reportState.budgetReport),
                _RsvpReportTab(report: reportState.rsvpReport),
                _VendorReportTab(report: reportState.vendorReport),
                _TaskReportTab(report: reportState.taskReport),
              ],
            ),
    );
  }
}

// ── Budget Report ─────────────────────────────────────────────────────────────

class _BudgetReportTab extends StatelessWidget {
  final BudgetReportData? report;
  const _BudgetReportTab({required this.report});

  @override
  Widget build(BuildContext context) {
    if (report == null) {
      return _NoDataState(
        icon: '💰',
        message: 'No budget set up yet.',
        detail: 'Set up your budget to generate a budget report.',
      );
    }
    final s = report!.summary;
    final fmt = NumberFormat.currency(symbol: s.currency, decimalDigits: 0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ReportHeader(
          title: 'Budget Report',
          generatedAt: report!.generatedAt,
        ),

        // Health banner
        _HealthBanner(isHealthy: s.isHealthy),
        const SizedBox(height: 16),

        // Summary card
        _SectionCard(
          title: 'Summary',
          children: [
            _ReportRow('Total Budget', fmt.format(s.totalBudget),
                bold: true),
            _ReportRow('Total Spent', fmt.format(s.totalSpent),
                valueColor: s.totalSpent > s.totalBudget
                    ? AppColors.error
                    : AppColors.textPrimary),
            _ReportRow('Remaining', fmt.format(s.totalRemaining),
                valueColor: s.totalRemaining < 0
                    ? AppColors.error
                    : AppColors.success),
            _ReportRow('Spending %',
                '${s.spendingPercent.toStringAsFixed(1)}%'),
            _ReportRow('Expense records', '${s.expenseCount}'),
            _ReportRow('Budget categories', '${s.categoryCount}'),
          ],
        ),
        const SizedBox(height: 16),

        // Spending progress
        _SectionCard(
          title: 'Budget Utilisation',
          children: [
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: (s.spendingPercent / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                s.spendingPercent >= 100
                    ? AppColors.error
                    : s.spendingPercent >= 90
                        ? AppColors.warning
                        : AppColors.success,
              ),
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 8),
            Text(
              '${s.spendingPercent.toStringAsFixed(1)}% of budget used',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Warnings
        if (s.hasOverBudgetCategories) ...[
          _AlertBanner(
            color: AppColors.error,
            icon: Icons.warning_amber_rounded,
            title: 'Over-budget categories',
            items: s.overBudgetCategories,
          ),
          const SizedBox(height: 12),
        ],
        if (s.hasNearLimitCategories) ...[
          _AlertBanner(
            color: AppColors.warning,
            icon: Icons.info_outline,
            title: 'Near limit (≥ 90%)',
            items: s.nearLimitCategories,
          ),
          const SizedBox(height: 12),
        ],

        // Category breakdown
        _SectionCard(
          title: 'Category Breakdown',
          children: report!.categorySummaries.map((c) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(c.categoryIcon,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(c.categoryName,
                              style: AppTextStyles.bodyMedium),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            fmt.format(c.spent),
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: c.isOverBudget
                                  ? AppColors.error
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'of ${fmt.format(c.allocated)}',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: (c.spendingPercent / 100).clamp(0.0, 1.0),
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      c.isOverBudget
                          ? AppColors.error
                          : c.isNearLimit
                              ? AppColors.warning
                              : AppColors.forestGreen,
                    ),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  if (c.expenseCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${c.expenseCount} expense${c.expenseCount == 1 ? '' : 's'} recorded',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),

        // Largest expense
        if (s.largestExpenseDescription != null) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Largest Expense',
            children: [
              _ReportRow(
                  s.largestExpenseDescription!,
                  fmt.format(s.largestExpenseAmount!),
                  bold: true),
            ],
          ),
        ],
      ],
    );
  }
}

// ── RSVP Report ───────────────────────────────────────────────────────────────

class _RsvpReportTab extends StatelessWidget {
  final RsvpReportData? report;
  const _RsvpReportTab({required this.report});

  @override
  Widget build(BuildContext context) {
    if (report == null) {
      return _NoDataState(
        icon: '💌',
        message: 'No RSVP data yet.',
        detail: 'Add guests and record RSVPs to generate this report.',
      );
    }
    final s = report!.stats;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ReportHeader(title: 'RSVP Report', generatedAt: report!.generatedAt),
        const SizedBox(height: 12),

        // Stat grid
        Row(
          children: [
            Expanded(
                child: _MiniStatCard(
                    value: '${s.attending}',
                    label: 'Attending',
                    color: AppColors.success)),
            const SizedBox(width: 8),
            Expanded(
                child: _MiniStatCard(
                    value: '${s.declined}',
                    label: 'Declined',
                    color: AppColors.error)),
            const SizedBox(width: 8),
            Expanded(
                child: _MiniStatCard(
                    value: '${s.maybe}',
                    label: 'Maybe',
                    color: AppColors.warning)),
            const SizedBox(width: 8),
            Expanded(
                child: _MiniStatCard(
                    value: '${s.pending}',
                    label: 'Pending',
                    color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 16),

        _SectionCard(
          title: 'Attendance Details',
          children: [
            _ReportRow('Total guests expected', '${s.totalAttending} people',
                bold: true),
            _ReportRow('Total invited', '${s.totalInvited} guests'),
            _ReportRow('Total in guest list', '${s.totalGuests} guests'),
            _ReportRow('Responses received', '${s.responded}'),
            _ReportRow(
                'Response rate', '${s.responseRate.toStringAsFixed(1)}%'),
            _ReportRow('Acceptance rate',
                '${s.acceptanceRate.toStringAsFixed(1)}%'),
          ],
        ),
        const SizedBox(height: 16),

        // Response rate progress
        _SectionCard(
          title: 'Response Progress',
          children: [
            LinearProgressIndicator(
              value: s.totalInvited > 0 ? s.responded / s.totalInvited : 0,
              backgroundColor: AppColors.divider,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.forestGreen),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 6),
            Text(
              '${s.responded} of ${s.totalInvited} guests responded',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            if (s.pending > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${s.pending} guest${s.pending == 1 ? '' : 's'} still pending',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Meal preferences
        if (s.mealCounts.isNotEmpty) ...[
          _SectionCard(
            title: 'Meal Preferences',
            children: s.mealCounts.entries.map((e) {
              final pct = s.totalAttending > 0
                  ? e.value / s.totalAttending
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: AppTextStyles.bodySmall),
                        Text(
                          '${e.value} guest${e.value == 1 ? '' : 's'} '
                          '(${(pct * 100).toStringAsFixed(0)}%)',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: pct,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.forestGreen),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Guest relation breakdown
        if (report!.relationBreakdown.isNotEmpty)
          _SectionCard(
            title: 'Guest Relations',
            children: report!.relationBreakdown.entries.map((e) {
              return _ReportRow(e.key, '${e.value} guest${e.value == 1 ? '' : 's'}');
            }).toList(),
          ),
      ],
    );
  }
}

// ── Vendor Report ─────────────────────────────────────────────────────────────

class _VendorReportTab extends StatelessWidget {
  final VendorReportData? report;
  const _VendorReportTab({required this.report});

  @override
  Widget build(BuildContext context) {
    if (report == null) {
      return _NoDataState(
        icon: '🏪',
        message: 'No vendor data.',
        detail: 'Vendor recommendations will appear here.',
      );
    }
    final r = report!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ReportHeader(title: 'Vendor Report', generatedAt: DateTime.now()),
        const SizedBox(height: 12),

        _SectionCard(
          title: 'Summary',
          children: [
            _ReportRow('Total vendors available', '${r.totalVendors}'),
            _ReportRow('Within-budget vendors', '${r.withinBudgetCount}'),
            _ReportRow('Categories covered',
                '${r.categoriesCovered.length}'),
            _ReportRow('Average rating',
                '${r.averageRating.toStringAsFixed(1)} / 5.0'),
          ],
        ),
        const SizedBox(height: 16),

        // Top rated
        if (r.topRated.isNotEmpty)
          _SectionCard(
            title: 'Top Rated Vendors',
            children: r.topRated.asMap().entries.map((entry) {
              final i = entry.key;
              final v = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: [
                              AppColors.warning,
                              AppColors.textSecondary,
                              AppColors.forestGreen,
                            ][i]
                            .withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: [
                            AppColors.warning,
                            AppColors.textSecondary,
                            AppColors.forestGreen,
                          ][i],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.businessName,
                              style: AppTextStyles.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w600)),
                          Text(v.category,
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 14, color: AppColors.warning),
                        const SizedBox(width: 3),
                        Text(
                          (v.rating ?? 0).toStringAsFixed(1),
                          style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 16),

        // Category breakdown
        _SectionCard(
          title: 'Vendors by Category',
          children: r.vendorsByCategory.entries.map((e) {
            return _ReportRow(
              e.key,
              '${e.value.length} vendor${e.value.length == 1 ? '' : 's'}',
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Task Report ───────────────────────────────────────────────────────────────

class _TaskReportTab extends StatelessWidget {
  final TaskReportData? report;
  const _TaskReportTab({required this.report});

  @override
  Widget build(BuildContext context) {
    if (report == null) {
      return _NoDataState(
        icon: '📋',
        message: 'No task data.',
        detail: 'Add tasks in the Task Planner to see progress here.',
      );
    }
    final r = report!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ReportHeader(title: 'Task Progress Report', generatedAt: DateTime.now()),
        const SizedBox(height: 12),

        // Progress circle-style card
        _SectionCard(
          title: 'Overall Progress',
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.progressLabel,
                        style: AppTextStyles.displaySmall.copyWith(
                            color: AppColors.forestGreen),
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: r.overallProgress,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.forestGreen),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ReportRow('Total tasks', '${r.totalTasks}'),
            _ReportRow('Completed', '${r.completedTasks}',
                valueColor: AppColors.success),
            _ReportRow('Remaining', '${r.remainingTasks}',
                valueColor:
                    r.remainingTasks > 0 ? AppColors.warning : AppColors.success),
            _ReportRow('Phases complete',
                '${r.completedPhases} / ${r.totalPhases}'),
          ],
        ),
        const SizedBox(height: 16),

        // Overdue tasks
        if (r.overdueTasks.isNotEmpty) ...[
          _AlertBanner(
            color: AppColors.error,
            icon: Icons.schedule,
            title: '${r.overdueTasks.length} overdue task${r.overdueTasks.length == 1 ? '' : 's'}',
            items: r.overdueTasks.map((t) => t.task).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // Upcoming tasks
        if (r.upcomingTasks.isNotEmpty) ...[
          _AlertBanner(
            color: AppColors.info,
            icon: Icons.upcoming_outlined,
            title: '${r.upcomingTasks.length} upcoming (next 30 days)',
            items: r.upcomingTasks.map((t) => t.task).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Phase-by-phase breakdown
        _SectionCard(
          title: 'Progress by Phase',
          children: r.phaseProgress.entries.map((e) {
            final pct = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(e.key,
                            style: AppTextStyles.bodySmall
                                .copyWith(fontWeight: FontWeight.w500)),
                      ),
                      Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        style: AppTextStyles.caption.copyWith(
                          color: pct == 1.0
                              ? AppColors.success
                              : AppColors.textSecondary,
                          fontWeight: pct == 1.0 ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      pct == 1.0 ? AppColors.success : AppColors.forestGreen,
                    ),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Shared report widgets ─────────────────────────────────────────────────────

class _ReportHeader extends StatelessWidget {
  final String title;
  final DateTime generatedAt;
  const _ReportHeader({required this.title, required this.generatedAt});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.headlineLarge),
        Text(
          'Generated ${DateFormat('MMM d, y — h:mm a').format(generatedAt)}',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        const Divider(),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _ReportRow(this.label, this.value,
      {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _MiniStatCard(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.headlineSmall.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _HealthBanner extends StatelessWidget {
  final bool isHealthy;
  const _HealthBanner({required this.isHealthy});

  @override
  Widget build(BuildContext context) {
    final color = isHealthy ? AppColors.success : AppColors.error;
    final icon = isHealthy ? Icons.check_circle_outline : Icons.warning_amber_rounded;
    final msg = isHealthy
        ? 'Budget is on track — no categories over budget.'
        : 'Action needed — one or more categories have exceeded their allocation.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg,
                  style:
                      AppTextStyles.bodySmall.copyWith(color: color))),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final List<String> items;

  const _AlertBanner({
    required this.color,
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle)),
                      Expanded(
                          child: Text(item,
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textPrimary))),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _NoDataState extends StatelessWidget {
  final String icon;
  final String message;
  final String detail;

  const _NoDataState(
      {required this.icon, required this.message, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(message, style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(detail,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
