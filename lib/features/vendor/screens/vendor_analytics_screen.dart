import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/messaging.dart';
import '../../../providers/vendor_own_provider.dart';
import '../../../widgets/wed_card.dart';

class VendorAnalyticsScreen extends ConsumerWidget {
  const VendorAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorOwnProvider);
    final inquiries = state.inquiries;
    final reviews = state.reviews;

    final inquiryCount = inquiries.length;
    final respondedCount = inquiries
        .where((i) =>
            i.status == InquiryStatus.responded ||
            i.status == InquiryStatus.quoted)
        .length;
    final bookedCount =
        inquiries.where((i) => i.status == InquiryStatus.booked).length;
    final responseRate = inquiryCount == 0
        ? '—'
        : '${((respondedCount / inquiryCount) * 100).toStringAsFixed(0)}%';
    final avgRating = reviews.isEmpty
        ? '—'
        : (reviews.fold(0.0, (s, r) => s + r.rating) / reviews.length)
            .toStringAsFixed(1);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        title: Text('Analytics',
            style: AppTextStyles.headlineMedium.copyWith(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Stats row ─────────────────────────────────────────────────────
          Row(
            children: [
              _StatCard(
                  value: '~247',
                  label: 'Profile\nViews',
                  trend: '+12%',
                  up: true),
              const SizedBox(width: 10),
              _StatCard(
                  value: '$inquiryCount',
                  label: 'Inquiries\nReceived',
                  trend: '',
                  up: true),
              const SizedBox(width: 10),
              _StatCard(
                  value: responseRate,
                  label: 'Response\nRate',
                  trend: '',
                  up: true),
              const SizedBox(width: 10),
              _StatCard(
                  value: avgRating,
                  label: 'Avg\nRating',
                  trend: '',
                  up: true),
            ],
          ),
          const SizedBox(height: 20),

          // ── Profile views chart (illustrative) ───────────────────────────
          WedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile Views (30 days)',
                    style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 3),
                            FlSpot(1, 5),
                            FlSpot(2, 4),
                            FlSpot(3, 7),
                            FlSpot(4, 6),
                            FlSpot(5, 9),
                            FlSpot(6, 8),
                            FlSpot(7, 11),
                            FlSpot(8, 10),
                            FlSpot(9, 14),
                            FlSpot(10, 12),
                            FlSpot(11, 15),
                          ],
                          isCurved: true,
                          color: AppColors.amber,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.amber.withAlpha(26),
                          ),
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Inquiry funnel ────────────────────────────────────────────────
          WedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Inquiry Funnel', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),
                _FunnelBar(
                    label: 'Profile Views',
                    value: 247,
                    max: 247,
                    color: AppColors.info),
                const SizedBox(height: 8),
                _FunnelBar(
                    label: 'Inquiries',
                    value: inquiryCount,
                    max: 247,
                    color: AppColors.warning),
                const SizedBox(height: 8),
                _FunnelBar(
                    label: 'Responded',
                    value: respondedCount,
                    max: 247,
                    color: AppColors.amber),
                const SizedBox(height: 8),
                _FunnelBar(
                    label: 'Booked',
                    value: bookedCount,
                    max: 247,
                    color: AppColors.success),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Revenue overview ──────────────────────────────────────────────
          WedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Revenue Overview', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 4),
                Text('Based on confirmed bookings',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _RevenueItem(
                        label: 'This Month', value: 'ZMW 85,000'),
                    _RevenueItem(label: 'Last Month', value: 'ZMW 72,000'),
                    _RevenueItem(label: 'YTD', value: 'ZMW 420,000'),
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

  const _StatCard({
    required this.value,
    required this.label,
    required this.trend,
    required this.up,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: AppColors.cardShadow, blurRadius: 3),
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTextStyles.headlineMedium
                    .copyWith(color: AppColors.forestGreen)),
            Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
            if (trend.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(up ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 10,
                      color: up ? AppColors.success : AppColors.error),
                  Text(trend,
                      style: AppTextStyles.caption.copyWith(
                          color: up ? AppColors.success : AppColors.error,
                          fontSize: 10)),
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

  const _FunnelBar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        SizedBox(
            width: 90, child: Text(label, style: AppTextStyles.caption)),
        Expanded(
          child: Stack(
            children: [
              Container(
                  height: 24,
                  decoration: BoxDecoration(
                      color: color.withAlpha(26),
                      borderRadius: BorderRadius.circular(4))),
              FractionallySizedBox(
                widthFactor: fraction,
                child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4))),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text('$value',
            style: AppTextStyles.caption
                .copyWith(fontWeight: FontWeight.w600)),
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
        Text(value,
            style: AppTextStyles.headlineSmall
                .copyWith(color: AppColors.forestGreen)),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
