import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/state/resource.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/vendor_feedback.dart';
import '../../../providers/vendor_own_provider.dart';
import '../../../widgets/wed_avatar.dart';

/// The vendor's private view of their own feedback — raw star ratings and
/// comments, visible only to this vendor (and admins). Nothing here is ever
/// shown to other couples; the public profile only shows the aggregate CRS
/// and badges computed from this data.
class VendorFeedbackScreen extends ConsumerWidget {
  const VendorFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(vendorOwnProvider).status == ResourceStatus.initial) {
      Future.microtask(() => ref.read(vendorOwnProvider.notifier).loadOwnVendorData());
    }
    final feedback = ref.watch(vendorFeedbackProvider);
    final visible = feedback.where((f) => !f.isFlagged).toList();

    final avg = visible.isEmpty
        ? 0.0
        : visible.fold(0.0, (s, f) => s + f.starRating) / visible.length;
    final recommendPct = visible.isEmpty
        ? 0
        : (visible.where((f) => f.starRating >= 4).length / visible.length * 100).round();

    final breakdown = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final f in visible) {
      breakdown[f.starRating] = (breakdown[f.starRating] ?? 0) + 1;
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
                        'PRIVATE — VISIBLE ONLY TO YOU',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.amber,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your feedback',
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
                _FeedbackSummaryCard(
                  average: avg,
                  total: visible.length,
                  recommendPct: recommendPct,
                  breakdown: breakdown,
                ),
                const SizedBox(height: 24),
                Text('All feedback',
                    style: AppTextStyles.headlineSmall
                        .copyWith(color: AppColors.forestGreen)),
                const SizedBox(height: 12),
                if (feedback.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No feedback yet.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...feedback.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FeedbackCard(feedback: f),
                      )),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary card ─────────────────────────────────────────────────────────────

class _FeedbackSummaryCard extends StatelessWidget {
  final double average;
  final int total;
  final int recommendPct;
  final Map<int, int> breakdown;

  const _FeedbackSummaryCard({
    required this.average,
    required this.total,
    required this.recommendPct,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  Text('$total submissions',
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
          if (total > 0) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.thumb_up_alt_outlined, size: 16, color: AppColors.forestGreen),
                const SizedBox(width: 8),
                Text('$recommendPct% of couples recommend you (public)',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ],
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

// ── Feedback card ─────────────────────────────────────────────────────────────

class _FeedbackCard extends StatelessWidget {
  final VendorFeedback feedback;
  const _FeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final name = feedback.coupleName ?? 'Anonymous couple';
    final dateStr = DateFormat('d MMM y').format(feedback.createdAt);

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
              WedAvatar(imageUrl: null, name: name, radius: 22),
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
                        if (feedback.isFlagged) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error.withAlpha(18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Excluded from score',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.error,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
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
          Row(
            children: [
              _StarRow(rating: feedback.starRating),
              if (feedback.onTime != null) ...[
                const SizedBox(width: 10),
                Icon(
                  feedback.onTime == OnTimeAnswer.yes
                      ? Icons.check_circle_outline
                      : feedback.onTime == OnTimeAnswer.no
                          ? Icons.cancel_outlined
                          : Icons.remove_circle_outline,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  switch (feedback.onTime!) {
                    OnTimeAnswer.yes => 'On time',
                    OnTimeAnswer.no => 'Not on time',
                    OnTimeAnswer.notApplicable => 'N/A',
                  },
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
          if (feedback.comment != null && feedback.comment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              feedback.comment!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
