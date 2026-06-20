import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/wed_card.dart';

enum _DateRange { week, month, year }

class PlatformAnalyticsScreen extends StatefulWidget {
  const PlatformAnalyticsScreen({super.key});

  @override
  State<PlatformAnalyticsScreen> createState() =>
      _PlatformAnalyticsScreenState();
}

class _PlatformAnalyticsScreenState extends State<PlatformAnalyticsScreen> {
  _DateRange _range = _DateRange.year;

  List<double> get _chartValues => switch (_range) {
        _DateRange.week => [
            12,
            19,
            8,
            24,
            16,
            30,
            22
          ],
        _DateRange.month => [
            45,
            62,
            58,
            71
          ],
        _DateRange.year => [
            10,
            18,
            24,
            35,
            40,
            52,
            58,
            65,
            72,
            78,
            84,
            92
          ],
      };

  List<String> get _chartLabels => switch (_range) {
        _DateRange.week => [
            'Mon',
            'Tue',
            'Wed',
            'Thu',
            'Fri',
            'Sat',
            'Sun'
          ],
        _DateRange.month => ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
        _DateRange.year => [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec'
          ],
      };

  String get _rangeLabel => switch (_range) {
        _DateRange.week => 'Last 7 days',
        _DateRange.month => 'Last 30 days',
        _DateRange.year => 'Last 12 months',
      };

  @override
  Widget build(BuildContext context) {
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
                  child: BarChart(
                    BarChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval:
                            (_chartValues.reduce((a, b) => a > b ? a : b) /
                                    4)
                                .ceilToDouble(),
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
                                  i >= _chartLabels.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _chartLabels[i],
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
                        _chartValues.length,
                        (i) => BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: _chartValues[i],
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
            children: const [
              Expanded(
                child: _MetricCard(
                  title: 'Total Users',
                  value: '4,829',
                  subtitle: '+247 this week',
                  positive: true,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Active Vendors',
                  value: '312',
                  subtitle: '+18 this week',
                  positive: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: _MetricCard(
                  title: 'Monthly Revenue',
                  value: r'$18,420',
                  subtitle: '+12% vs last month',
                  positive: true,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Avg Session',
                  value: '8.4 min',
                  subtitle: '+1.2 min vs last month',
                  positive: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Revenue by Plan ────────────────────────────────────
          WedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Revenue by Plan',
                    style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                      sections: [
                        PieChartSectionData(
                          value: 60,
                          color: AppColors.secondary,
                          title: '60%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          radius: 56,
                        ),
                        PieChartSectionData(
                          value: 35,
                          color: AppColors.goldPremium,
                          title: '35%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          radius: 56,
                        ),
                        PieChartSectionData(
                          value: 5,
                          color: AppColors.adminNeutralBg,
                          title: '5%',
                          titleStyle: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
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
                    _PieLegend(
                        color: AppColors.secondary, label: 'Pro'),
                    SizedBox(width: 20),
                    _PieLegend(
                        color: AppColors.goldPremium,
                        label: 'Premium'),
                    SizedBox(width: 20),
                    _PieLegend(
                        color: AppColors.adminNeutralBg,
                        label: 'Free'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Top Categories ─────────────────────────────────────
          WedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Top Categories by Inquiries',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    )),
                SizedBox(height: 14),
                _CategoryBar(
                    label: 'Photography', value: 89, max: 89),
                SizedBox(height: 10),
                _CategoryBar(label: 'Venue', value: 76, max: 89),
                SizedBox(height: 10),
                _CategoryBar(
                    label: 'Catering', value: 64, max: 89),
                SizedBox(height: 10),
                _CategoryBar(
                    label: 'Floristry', value: 41, max: 89),
                SizedBox(height: 10),
                _CategoryBar(label: 'Music', value: 33, max: 89),
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

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.positive,
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
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                positive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 12,
                color:
                    positive ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: positive
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
