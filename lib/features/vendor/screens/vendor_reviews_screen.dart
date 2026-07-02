import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/review.dart';
import '../../../providers/vendor_own_provider.dart';

class VendorReviewsScreen extends ConsumerWidget {
  const VendorReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(vendorReviewsProvider);
    final approved =
        reviews.where((r) => r.status == ReviewStatus.approved).toList();

    final avg = reviews.isEmpty
        ? 0.0
        : reviews.fold(0.0, (s, r) => s + r.rating) / reviews.length;

    final breakdown = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviews) {
      breakdown[r.rating] = (breakdown[r.rating] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // ── Dark green header ────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: AppColors.forestGreen,
            expandedHeight: 120,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${approved.length} VERIFIED REVIEWS',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.amber,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Customer reviews',
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
                _RatingSummaryCard(
                  average: avg,
                  total: reviews.length,
                  breakdown: breakdown,
                ),
                const SizedBox(height: 24),
                Text('All reviews',
                    style: AppTextStyles.headlineSmall
                        .copyWith(color: AppColors.forestGreen)),
                const SizedBox(height: 12),
                ...reviews.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReviewCard(review: r),
                    )),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rating summary card ───────────────────────────────────────────────────────

class _RatingSummaryCard extends StatelessWidget {
  final double average;
  final int total;
  final Map<int, int> breakdown;

  const _RatingSummaryCard({
    required this.average,
    required this.total,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(
                average.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forestGreen,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              _StarRow(rating: average.round()),
              const SizedBox(height: 4),
              Text('$total reviews',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = breakdown[star] ?? 0;
                final fill = total > 0 ? count / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text('$star',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded,
                          size: 12, color: AppColors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: fill,
                            backgroundColor: const Color(0xFFEEEBE4),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.amber),
                            minHeight: 7,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 18,
                        child: Text('$count',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary),
                            textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 16,
          color: AppColors.amber,
        ),
      ),
    );
  }
}

// ── Review card ───────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final isVerified = review.status == ReviewStatus.approved;
    final name = review.coupleName ?? 'Anonymous';
    final dateStr = review.publishedAt != null
        ? DateFormat('d MMM y').format(review.publishedAt!)
        : DateFormat('d MMM y').format(review.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.amber, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(name,
                              style: AppTextStyles.titleMedium
                                  .copyWith(color: AppColors.forestGreen),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.forestGreen.withAlpha(18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded,
                                    size: 10, color: AppColors.forestGreen),
                                const SizedBox(width: 3),
                                Text(
                                  'Verified booking',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.forestGreen,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(dateStr,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _StarRow(rating: review.rating),
          const SizedBox(height: 8),
          Text(
            review.body,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
