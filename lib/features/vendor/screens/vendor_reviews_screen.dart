import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class VendorReviewsScreen extends StatelessWidget {
  const VendorReviewsScreen({super.key});

  static final _reviews = [
    _Review(
      name: 'Chanda & Mwila',
      date: '18 May 2026',
      rating: 5,
      text:
          'Mukuba Gardens was absolutely breathtaking. The staff were professional and the setup was beyond our expectations. Highly recommend!',
      isVerified: true,
    ),
    _Review(
      name: 'Natasha & Temba',
      date: '3 April 2026',
      rating: 5,
      text:
          'We could not have chosen a better venue. Every detail was handled with care and the team made our special day truly unforgettable.',
      isVerified: true,
    ),
    _Review(
      name: 'Bwalya & Kunda',
      date: '12 February 2026',
      rating: 4,
      text:
          'Beautiful venue with great outdoor space. The catering coordination was seamless. Parking could be a little more organised but overall fantastic.',
      isVerified: true,
    ),
    _Review(
      name: 'Mutale & Phiri',
      date: '28 January 2026',
      rating: 5,
      text:
          'Exceeded every expectation. The green garden backdrop made our photos stunning. The team is responsive, friendly, and incredibly helpful.',
      isVerified: false,
    ),
    _Review(
      name: 'Ruth & Chola',
      date: '5 January 2026',
      rating: 4,
      text:
          'Lovely venue and great value. The lighting at night was magical. We\'d definitely recommend Mukuba Gardens to anyone planning their wedding.',
      isVerified: true,
    ),
  ];

  static double get _average =>
      _reviews.fold(0.0, (s, r) => s + r.rating) / _reviews.length;

  static Map<int, int> get _breakdown {
    final m = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _reviews) {
      m[r.rating] = (m[r.rating] ?? 0) + 1;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final avg = _average;
    final breakdown = _breakdown;

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
                        '${_reviews.length} VERIFIED REVIEWS',
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

                // ── Ratings summary card ─────────────────────────────────
                _RatingSummaryCard(
                  average: avg,
                  total: _reviews.length,
                  breakdown: breakdown,
                ),
                const SizedBox(height: 24),

                // ── Review cards ─────────────────────────────────────────
                Text('All reviews',
                    style: AppTextStyles.headlineSmall
                        .copyWith(color: AppColors.forestGreen)),
                const SizedBox(height: 12),
                ..._reviews.map((r) => Padding(
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

// ── Rating summary card ────────────────────────────────────────────────────────

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
          // Big average number
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
          // Breakdown bars
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

// ── Review card ────────────────────────────────────────────────────────────────

class _Review {
  final String name;
  final String date;
  final int rating;
  final String text;
  final bool isVerified;

  const _Review({
    required this.name,
    required this.date,
    required this.rating,
    required this.text,
    required this.isVerified,
  });
}

class _ReviewCard extends StatelessWidget {
  final _Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
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
          // Avatar + name + date
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
                    review.name.substring(0, 1),
                    style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.amber,
                        fontWeight: FontWeight.w700),
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
                        Text(review.name,
                            style: AppTextStyles.titleMedium
                                .copyWith(color: AppColors.forestGreen)),
                        if (review.isVerified) ...[
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
                                    size: 10,
                                    color: AppColors.forestGreen),
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
                    Text(review.date,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Stars
          _StarRow(rating: review.rating),
          const SizedBox(height: 8),
          // Review text
          Text(
            review.text,
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
