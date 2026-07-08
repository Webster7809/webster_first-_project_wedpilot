import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/wed_card.dart';

enum _DateRange { week, month, year }

class PlatformAnalyticsScreen extends ConsumerStatefulWidget {
  const PlatformAnalyticsScreen({super.key});

  @override
  ConsumerState<PlatformAnalyticsScreen> createState() =>
      _PlatformAnalyticsScreenState();
}

class _PlatformAnalyticsScreenState extends ConsumerState<PlatformAnalyticsScreen> {
  _DateRange _range = _DateRange.year;

  List<String> get _weekLabels {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return names[day.weekday - 1];
    });
  }

  List<String> get _yearLabels {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    return List.generate(12, (i) {
      final monthsAgo = 11 - i;
      final month = DateTime(now.year, now.month - monthsAgo, 1);
      return names[month.month - 1];
    });
  }

  String get _rangeLabel => switch (_range) {
        _DateRange.week => 'Last 7 days',
        _DateRange.month => 'Last 4 weeks',
        _DateRange.year => 'Last 12 months',
      };

  @override
  Widget build(BuildContext context) {
    final analytics = ref.watch(adminAnalyticsProvider).valueOrNull;
    final overview = ref.watch(adminOverviewProvider).valueOrNull;

    final chartValues = (switch (_range) {
          _DateRange.week => analytics?.userGrowthWeek,
          _DateRange.month => analytics?.userGrowthMonth,
          _DateRange.year => analytics?.userGrowthYear,
        } ??
        const [])
        .map((v) => v.toDouble())
        .toList();
    final chartLabels = switch (_range) {
      _DateRange.week => _weekLabels,
      _DateRange.month => const ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
      _DateRange.year => _yearLabels,
    };

    final newSignupsThisWeek =
        analytics?.userGrowthWeek.fold<int>(0, (a, b) => a + b) ?? 0;
    final totalUsers = (overview?.activeCouples ?? 0) + (overview?.registeredVendors ?? 0);
    final tiers = analytics?.vendorTierDistribution ?? const {'free': 0, 'pro': 0, 'premium': 0};
    final totalVendorsForTiers = tiers.values.fold<int>(0, (a, b) => a + b);
    final topCategories = analytics?.topCategories ?? const [];
    final maxCategoryCount = topCategories.isEmpty
        ? 1
        : topCategories.map((c) => c.count).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: AppColors.adminPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.divider,
        title: Text(
          'Reports & Analytics',
          style: AppTextStyles.headlineSmall
              .copyWith(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── User Growth Chart ──────────────────────────────────
          WedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('User Growth',
                        style: AppTextStyles.headlineSmall),
                    // ── Date range toggle ──────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.adminPage,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _RangeChip(
                            label: '7D',
                            selected: _range == _DateRange.week,
                            onTap: () =>
                                setState(() => _range = _DateRange.week),
                          ),
                          _RangeChip(
                            label: '30D',
                            selected: _range == _DateRange.month,
                            onTap: () =>
                                setState(() => _range = _DateRange.month),
                          ),
                          _RangeChip(
                            label: '12M',
                            selected: _range == _DateRange.year,
                            onTap: () =>
                                setState(() => _range = _DateRange.year),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _rangeLabel,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 180,
                  child: chartValues.every((v) => v == 0)
                      ? Center(
                          child: Text(
                            'No signups in this period yet.',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        )
                      : BarChart(
                    BarChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval:
                            (chartValues.reduce((a, b) => a > b ? a : b) /
                                    4)
                                .ceilToDouble()
                                .clamp(1.0, double.infinity),
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: AppColors.adminNeutralBg,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (value, _) {
                              final i = value.toInt();
                              if (i < 0 ||
                                  i >= chartLabels.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  chartLabels[i],
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 9,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(
                        chartValues.length,
                        (i) => BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: chartValues[i],
                              color: AppColors.secondary,
                              width: _range == _DateRange.year
                                  ? 14
                                  : _range == _DateRange.month
                                      ? 28
                                      : 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Metric Cards ───────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Total Users',
                  value: totalUsers.toString(),
                  subtitle: '+$newSignupsThisWeek this week',
                  positive: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Active Vendors',
                  value: (overview?.registeredVendors ?? 0).toString(),
                  subtitle: '${overview?.pendingVendorsCount ?? 0} pending review',
                  positive: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Monthly Revenue',
                  value: '—',
                  subtitle: 'Coming soon — no payment system yet',
                  positive: true,
                  comingSoon: true,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Avg Session',
                  value: '—',
                  subtitle: 'Coming soon — usage tracking planned',
                  positive: true,
                  comingSoon: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Vendor Tier Distribution ────────────────────────────
          WedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Vendor Tier Distribution',
                    style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),
                if (totalVendorsForTiers == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No vendors registered yet.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else ...[
                  SizedBox(
                    height: 160,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 32,
                        sections: [
                          if ((tiers['free'] ?? 0) > 0)
                            PieChartSectionData(
                              value: (tiers['free'] ?? 0).toDouble(),
                              color: AppColors.adminNeutralBg,
                              title: '${tiers['free']}',
                              titleStyle: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSecondary),
                              radius: 56,
                            ),
                          if ((tiers['pro'] ?? 0) > 0)
                            PieChartSectionData(
                              value: (tiers['pro'] ?? 0).toDouble(),
                              color: AppColors.secondary,
                              title: '${tiers['pro']}',
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              radius: 56,
                            ),
                          if ((tiers['premium'] ?? 0) > 0)
                            PieChartSectionData(
                              value: (tiers['premium'] ?? 0).toDouble(),
                              color: AppColors.goldPremium,
                              title: '${tiers['premium']}',
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              radius: 56,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _PieLegend(color: AppColors.adminNeutralBg, label: 'Free'),
                      SizedBox(width: 20),
                      _PieLegend(color: AppColors.secondary, label: 'Pro'),
                      SizedBox(width: 20),
                      _PieLegend(color: AppColors.goldPremium, label: 'Premium'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Top Categories ─────────────────────────────────────
          WedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Top Categories by Inquiries',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 14),
                if (topCategories.isEmpty)
                  Text(
                    'No inquiries have been sent yet.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  )
                else
                  for (int i = 0; i < topCategories.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _CategoryBar(
                      label: topCategories[i].category,
                      value: topCategories[i].count,
                      max: maxCategoryCount,
                    ),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Range Chip ────────────────────────────────────────────────────────────────

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.adminIndigo : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color:
                selected ? Colors.white : AppColors.textSecondary,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Metric Card ───────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final bool positive;
  final bool comingSoon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.positive,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
                color: comingSoon ? AppColors.textHint : AppColors.textPrimary,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (!comingSoon)
                Icon(
                  positive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 12,
                  color:
                      positive ? AppColors.success : AppColors.error,
                ),
              if (!comingSoon) const SizedBox(width: 3),
              Flexible(
                child: Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: comingSoon
                        ? AppColors.textHint
                        : positive
                            ? AppColors.success
                            : AppColors.error,
                    fontSize: 10,
                  ),
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

// ── Pie Legend ────────────────────────────────────────────────────────────────

class _PieLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _PieLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption
              .copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── Category Bar ──────────────────────────────────────────────────────────────

class _CategoryBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  const _CategoryBar(
      {required this.label,
      required this.value,
      required this.max});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value / max,
              backgroundColor: AppColors.adminNeutralBg,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.secondary),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$value',
          style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
