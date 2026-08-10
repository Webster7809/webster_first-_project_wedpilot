import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/vendor_category_images.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/vendor_provider.dart';
import '../../../widgets/vendor_hero_image.dart';
import '../../../widgets/wed_card.dart';
import '../../../widgets/wed_empty_state.dart';
import '../../../widgets/wed_snack_bar.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  Future<void> _remove(BuildContext context, WidgetRef ref, String vendorId) async {
    final error = await ref.read(wishlistProvider.notifier).toggle(vendorId);
    if (error != null && context.mounted) {
      showWedSnackBar(context, error, type: SnackType.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistIds = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Wishlist')),
      body: wishlistIds.isEmpty
          ? WedEmptyState(
              icon: Icons.favorite_outlined,
              title: 'Your wishlist is empty',
              message: 'Tap the heart on any vendor to save them here',
              ctaLabel: 'Browse Vendors',
              onCtaTap: () => context.go('/couple/vendors'),
              imageUrl: VendorCategoryImages.galleryFor('Decor & flowers')[0],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wishlistIds.length,
              itemBuilder: (_, i) {
                final vendorId = wishlistIds[i];
                return _WishlistItem(
                  vendorId: vendorId,
                  onRemove: () => _remove(context, ref, vendorId),
                  onTap: () => context.push('/couple/vendors/$vendorId'),
                );
              },
            ),
    );
  }
}

class _WishlistItem extends ConsumerWidget {
  final String vendorId;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _WishlistItem({required this.vendorId, required this.onRemove, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorAsync = ref.watch(vendorDetailProvider(vendorId));

    return vendorAsync.when(
      loading: () => const SizedBox(height: 80, child: Center(child: LinearProgressIndicator())),
      error: (_, _) => const SizedBox.shrink(),
      data: (vendor) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: WedCard(
          onTap: onTap,
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: VendorHeroImage(
                    vendor: vendor,
                    height: 56,
                    memCacheWidth: 112,
                    single: true,
                    showBadge: false,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vendor.businessName, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 4),
                    Text(vendor.category, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 12, color: AppColors.goldPremium),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${vendor.rating?.toStringAsFixed(1) ?? '—'} · ${vendor.location ?? ''}',
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove from wishlist',
                icon: const Icon(Icons.favorite, color: AppColors.goldDeep),
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
