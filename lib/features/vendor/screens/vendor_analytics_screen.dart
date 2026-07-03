import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/resource.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/messaging.dart';
import '../../../providers/vendor_own_provider.dart';
import '../../../widgets/wed_card.dart';

class VendorAnalyticsScreen extends ConsumerWidget {
  const VendorAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownState = ref.watch(vendorOwnProvider);
    if (ownState.status == ResourceStatus.initial) {
      Future.microtask(() => ref.read(vendorOwnProvider.notifier).loadOwnVendorData());
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        title: Text('Analytics',
            style: AppTextStyles.headlineMedium.copyWith(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ownState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (message) => Center(
          child: Text(message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ),
        data: (data) => _AnalyticsBody(inquiries: data.inquiries, reviews: data.reviews),
      ),
    );
  }
}

class _AnalyticsBody extends ConsumerWidget {
  final List<Inquiry> inquiries;
  final List<dynamic> reviews;

  const _AnalyticsBody({required this.inquiries, required this.reviews});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenueAsync = ref.watch(vendorRevenueProvider);

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
        : (reviews.fold(0.0, (s, dynamic r) => s + (r.rating as num)) / reviews.length)
            .toStringAsFixed(1);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Stats row ─────────────────────────────────────────────────────
        Row(
          children: [
            _StatCard(value: '$inquiryCount', label: 'Inquiries\nReceived'),
            const SizedBox(width: 10),
            _StatCard(value: responseRate, label: 'Response\nRate'),
            const SizedBox(width: 10),
            _StatCard(value: avgRating, label: 'Avg\nRating'),
            const SizedBox(width: 10),
            _StatCard(value: '$bookedCount', label: 'Bookings'),
          ],
        ),
        const SizedBox(height: 20),

        // ── Inquiry funnel ────────────────────────────────────────────────
        WedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Inquiry Funnel', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              if (inquiryCount == 0)
                Text(
                  'No inquiries yet — this fills in once couples start reaching out.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                )
              else ...[
                _FunnelBar(
                    label: 'Inquiries',
                    value: inquiryCount,
                    max: inquiryCount,
                    color: AppColors.warning),
                const SizedBox(height: 8),
                _FunnelBar(
                    label: 'Responded',
                    value: respondedCount,
                    max: inquiryCount,
                    color: AppColors.amber),
                const SizedBox(height: 8),
                _FunnelBar(
                    label: 'Booked',
                    value: bookedCount,
                    max: inquiryCount,
                    color: AppColors.success),
              ],
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
              revenueAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Text(
                  'Could not load revenue right now.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
                data: (revenue) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _RevenueItem(label: 'This Month', value: _fmt(revenue.thisMonth)),
                    _RevenueItem(label: 'Last Month', value: _fmt(revenue.lastMonth)),
                    _RevenueItem(label: 'YTD', value: _fmt(revenue.yearToDate)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Profile views (not yet tracked) ─────────────────────────────────
        WedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile Views', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Coming soon — view tracking is on the roadmap.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(double amount) => 'ZMW ${amount.toStringAsFixed(0)}';
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

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
