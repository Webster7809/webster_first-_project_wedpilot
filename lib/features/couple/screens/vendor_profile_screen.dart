import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/vendor_provider.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_snack_bar.dart';

class VendorProfileScreen extends ConsumerWidget {
  final String vendorId;
  const VendorProfileScreen({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorAsync = ref.watch(vendorDetailProvider(vendorId));
    final wishlist = ref.watch(wishlistProvider);
    final ratings = ref.watch(vendorRatingsProvider);

    return vendorAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Failed to load vendor: $e')),
      ),
      data: (vendor) {
        final isWishlisted = wishlist.contains(vendor.id);
        final myRating = ratings[vendor.id];

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: AppColors.primary.withAlpha(102),
                        child: const Center(
                            child: Text('📷',
                                style: TextStyle(fontSize: 80))),
                      ),
                      if (vendor.isVerified)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.info,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Verified',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                        isWishlisted
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: isWishlisted
                            ? AppColors.secondary
                            : Colors.white),
                    onPressed: () {
                      ref
                          .read(wishlistProvider.notifier)
                          .toggle(vendor.id);
                      showWedSnackBar(
                        context,
                        isWishlisted
                            ? 'Removed from wishlist'
                            : 'Added to wishlist! ❤️',
                        type: isWishlisted
                            ? SnackType.info
                            : SnackType.success,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined,
                        color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Vendor header ─────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(vendor.businessName,
                                  style: AppTextStyles.displaySmall),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      size: 14,
                                      color: AppColors.textSecondary),
                                  const SizedBox(width: 2),
                                  Text(vendor.location ?? '',
                                      style: AppTextStyles.bodySmall),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    size: 16,
                                    color: AppColors.goldPremium),
                                const SizedBox(width: 4),
                                Text(
                                    vendor.rating
                                            ?.toStringAsFixed(1) ??
                                        '—',
                                    style: AppTextStyles.titleMedium),
                              ],
                            ),
                            Text('${vendor.reviewCount} reviews',
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: vendor.styleTags
                          .map((t) => Chip(
                              label: Text(t),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    if (vendor.description != null)
                      Text(vendor.description!,
                          style: AppTextStyles.bodyMedium
                              .copyWith(height: 1.6)),
                    const SizedBox(height: 20),

                    // ── Services & Pricing ────────────────────
                    Text('Services & Pricing',
                        style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 12),
                    ...vendor.services.map((s) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(s.title,
                                          style:
                                              AppTextStyles.titleMedium),
                                      if (s.description != null)
                                        Text(s.description!,
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                    color: AppColors
                                                        .textSecondary)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                        '\$${s.priceMin.toStringAsFixed(0)}',
                                        style: AppTextStyles.titleMedium
                                            .copyWith(
                                                color:
                                                    AppColors.secondary)),
                                    Text(
                                        'to \$${s.priceMax.toStringAsFixed(0)}',
                                        style: AppTextStyles.caption),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )),

                    const SizedBox(height: 20),

                    // ── AI Score ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.goldPremium.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.goldPremium.withAlpha(77)),
                      ),
                      child: Row(
                        children: [
                          const Text('🌟',
                              style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'AI Reputation Score: ${vendor.compositeScore.toStringAsFixed(0)}/100',
                                    style: AppTextStyles.titleMedium),
                                Text(
                                    'Based on ratings, response rate & booking conversion',
                                    style: AppTextStyles.caption.copyWith(
                                        color:
                                            AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Couple rating section ─────────────────
                    _VendorRatingSection(
                      vendorId: vendor.id,
                      vendorName: vendor.businessName,
                      currentRating: myRating,
                      onRate: (stars) {
                        ref
                            .read(vendorRatingsProvider.notifier)
                            .rate(vendor.id, stars);
                        showWedSnackBar(
                          context,
                          'You rated ${vendor.businessName} $stars star${stars == 1 ? '' : 's'} ⭐',
                          type: SnackType.success,
                        );
                      },
                      onUnrate: () {
                        ref
                            .read(vendorRatingsProvider.notifier)
                            .unrate(vendor.id);
                        showWedSnackBar(
                          context,
                          'Your rating has been removed',
                          type: SnackType.info,
                        );
                      },
                    ),

                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: WedButton(
                      label: 'Send Inquiry',
                      onPressed: () {
                        context.push('/couple/messages');
                        showWedSnackBar(
                            context,
                            'Inquiry sent to ${vendor.businessName}!',
                            type: SnackType.success);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Interactive star rating widget ──────────────────────────────────────────

class _VendorRatingSection extends StatelessWidget {
  final String vendorId;
  final String vendorName;
  final int? currentRating;
  final void Function(int stars) onRate;
  final VoidCallback onUnrate;

  const _VendorRatingSection({
    required this.vendorId,
    required this.vendorName,
    required this.currentRating,
    required this.onRate,
    required this.onUnrate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rate_review_outlined,
                  size: 18, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text('Rate this Vendor',
                  style: AppTextStyles.headlineSmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            currentRating == null
                ? 'Tap a star to share your experience'
                : 'Your rating: $currentRating / 5  —  tap the same star to remove',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),

          // Star row
          Row(
            children: List.generate(5, (i) {
              final starValue = i + 1;
              final filled = currentRating != null &&
                  starValue <= currentRating!;
              return GestureDetector(
                onTap: () {
                  if (currentRating == starValue) {
                    // Tapping the same star removes the rating
                    onUnrate();
                  } else {
                    onRate(starValue);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: child,
                    ),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      key: ValueKey('$starValue-$filled'),
                      size: 40,
                      color: filled
                          ? AppColors.goldPremium
                          : AppColors.textHint,
                    ),
                  ),
                ),
              );
            }),
          ),

          // Remove rating button — only visible when rated
          if (currentRating != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onUnrate,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.close, size: 14, color: AppColors.error),
                  const SizedBox(width: 4),
                  Text(
                    'Remove my rating',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.error),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
