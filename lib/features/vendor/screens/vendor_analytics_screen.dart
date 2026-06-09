import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/wed_card.dart';

class VendorAnalyticsScreen extends StatelessWidget {
  const VendorAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats row
          Row(
            children: const [
              _StatCard(value: '247', label: 'Profile\nViews', trend: '+12%', up: true),
              SizedBox(width: 10),
              _StatCard(value: '18', label: 'Inquiries\nReceived', trend: '+5%', up: true),
              SizedBox(width: 10),
              _StatCard(value: '67%', label: 'Response\nRate', trend: '-3%', up: false),
              SizedBox(width: 10),
              _StatCard(value: '4.9', label: 'Avg\nRating', trend: '+0.1', up: true),
            ],
          ),
          const SizedBox(height: 20),

          // Profile views chart
          WedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile Views (30 days)', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 3), FlSpot(1, 5), FlSpot(2, 4), FlSpot(3, 7),
                            FlSpot(4, 6), FlSpot(5, 9), FlSpot(6, 8), FlSpot(7, 11),
                            FlSpot(8, 10), FlSpot(9, 14), FlSpot(10, 12), FlSpot(11, 15),
                          ],
                          isCurved: true,
                          color: AppColors.secondary,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.secondary.withOpacity(0.1),
                          ),
                          dotData: FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Inquiry funnel
          WedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Inquiry Funnel', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),
                const _FunnelBar(label: 'Profile Views', value: 247, max: 247, color: AppColors.info),
                const SizedBox(height: 8),
                const _FunnelBar(label: 'Inquiries', value: 18, max: 247, color: AppColors.warning),
                const SizedBox(height: 8),
                const _FunnelBar(label: 'Responded', value: 12, max: 247, color: AppColors.secondary),
                const SizedBox(height: 8),
                const _FunnelBar(label: 'Booked', value: 5, max: 247, color: AppColors.success),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Revenue trend
          WedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Revenue Overview', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 4),
                Text('Based on confirmed bookings', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _RevenueItem(label: 'This Month', value: '\$8,500'),
                    _RevenueItem(label: 'Last Month', value: '\$7,200'),
                    _RevenueItem(label: 'YTD', value: '\$42,000'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String trend;
  final bool up;
  const _StatCard({required this.value, required this.label, required this.trend, required this.up});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 3)],
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.headlineMedium.copyWith(color: AppColors.secondary)),
            Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(up ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 10, color: up ? AppColors.success : AppColors.error),
                Text(trend, style: AppTextStyles.caption.copyWith(
                    color: up ? AppColors.success : AppColors.error, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FunnelBar extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;
  const _FunnelBar({required this.label, required this.value, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: AppTextStyles.caption)),
        Expanded(
          child: Stack(
            children: [
              Container(height: 24, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4))),
              FractionallySizedBox(
                widthFactor: value / max,
                child: Container(height: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text('$value', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _RevenueItem extends StatelessWidget {
  final String label;
  final String value;
  const _RevenueItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.headlineSmall.copyWith(color: AppColors.secondary)),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
