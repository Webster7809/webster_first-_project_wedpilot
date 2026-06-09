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

    return vendorAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Failed to load vendor: $e')),
      ),
      data: (vendor) {
        final isWishlisted = wishlist.contains(vendor.id);
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
                        color: AppColors.primary.withOpacity(0.4),
                        child: const Center(child: Text('📷', style: TextStyle(fontSize: 80))),
                      ),
                      if (vendor.isVerified)
                        Positioned(
                          bottom: 16, left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.info,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text('Verified', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border,
                        color: isWishlisted ? AppColors.secondary : Colors.white),
                    onPressed: () {
                      ref.read(wishlistProvider.notifier).toggle(vendor.id);
                      showWedSnackBar(
                        context,
                        isWishlisted ? 'Removed from wishlist' : 'Added to wishlist! ❤️',
                        type: isWishlisted ? SnackType.info : SnackType.success,
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(vendor.businessName, style: AppTextStyles.displaySmall),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 2),
                                  Text(vendor.location ?? '', style: AppTextStyles.bodySmall),
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
                                const Icon(Icons.star, size: 16, color: AppColors.goldPremium),
                                const SizedBox(width: 4),
                                Text(vendor.rating?.toStringAsFixed(1) ?? '—',
                                    style: AppTextStyles.titleMedium),
                              ],
                            ),
                            Text('${vendor.reviewCount} reviews', style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: vendor.styleTags
                          .map((t) => Chip(label: Text(t), padding: EdgeInsets.zero, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    if (vendor.description != null)
                      Text(vendor.description!, style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
                    const SizedBox(height: 20),

                    // Services
                    Text('Services & Pricing', style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 12),
                    ...vendor.services.map((s) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.title, style: AppTextStyles.titleMedium),
                                      if (s.description != null)
                                        Text(s.description!,
                                            style: AppTextStyles.caption.copyWith(
                                                color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('\$${s.priceMin.toStringAsFixed(0)}',
                                        style: AppTextStyles.titleMedium.copyWith(
                                            color: AppColors.secondary)),
                                    Text('to \$${s.priceMax.toStringAsFixed(0)}',
                                        style: AppTextStyles.caption),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )),

                    const SizedBox(height: 20),
                    // AI Score
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.goldPremium.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.goldPremium.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Text('🌟', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('AI Reputation Score: ${vendor.compositeScore.toStringAsFixed(0)}/100',
                                    style: AppTextStyles.titleMedium),
                                Text('Based on ratings, response rate & booking conversion',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                        showWedSnackBar(context, 'Inquiry sent to ${vendor.businessName}!',
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
