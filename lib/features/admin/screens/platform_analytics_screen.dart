import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/wed_card.dart';

class PlatformAnalyticsScreen extends StatelessWidget {
  const PlatformAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Platform Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User Growth (Last 30 Days)', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: BarChart(
                    BarChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(12, (i) => BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: (10 + i * 3.5 + (i % 3 * 4)).toDouble(),
                            color: AppColors.secondary,
                            width: 12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      )),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: _MetricCard(title: 'Total Users', value: '4,829', subtitle: '+247 this week')),
              SizedBox(width: 12),
              Expanded(child: _MetricCard(title: 'Active Vendors', value: '312', subtitle: '+18 this week')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: _MetricCard(title: 'Monthly Revenue', value: '\$18,420', subtitle: '+12% vs last month')),
              SizedBox(width: 12),
              Expanded(child: _MetricCard(title: 'Avg Session', value: '8.4 min', subtitle: '+1.2 min vs last month')),
            ],
          ),
          const SizedBox(height: 16),
          WedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Revenue by Plan', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(value: 60, color: AppColors.secondary, title: 'Pro\n60%', titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        PieChartSectionData(value: 35, color: AppColors.goldPremium, title: 'Premium\n35%', titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        PieChartSectionData(value: 5, color: AppColors.divider, title: 'Free\n5%', titleStyle: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          WedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Top Categories by Inquiries', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 12),
                const _CategoryBar(label: 'Photography', value: 89, max: 89),
                const SizedBox(height: 8),
                const _CategoryBar(label: 'Venue', value: 76, max: 89),
                const SizedBox(height: 8),
                const _CategoryBar(label: 'Catering', value: 64, max: 89),
                const SizedBox(height: 8),
                const _CategoryBar(label: 'Floristry', value: 41, max: 89),
                const SizedBox(height: 8),
                const _CategoryBar(label: 'Music', value: 33, max: 89),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  const _MetricCard({required this.title, required this.value, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.headlineMedium.copyWith(color: AppColors.secondary)),
          Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.success)),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  const _CategoryBar({required this.label, required this.value, required this.max});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: AppTextStyles.caption)),
        Expanded(
          child: LinearProgressIndicator(
            value: value / max,
            backgroundColor: AppColors.divider,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 8),
        Text('$value', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
