import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/vendor_provider.dart';
import '../../../widgets/wed_button.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistIds = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Wishlist')),
      body: wishlistIds.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('❤️', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 16),
                  Text('Your wishlist is empty', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 8),
                  Text('Tap the heart on any vendor to save them here',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  WedButton(
                    label: 'Browse Vendors',
                    onPressed: () => context.go('/couple/vendors'),
                    width: 200,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wishlistIds.length,
              itemBuilder: (_, i) {
                final vendorId = wishlistIds[i];
                return _WishlistItem(
                  vendorId: vendorId,
                  onRemove: () => ref.read(wishlistProvider.notifier).toggle(vendorId),
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
      data: (vendor) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(77),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('📷', style: TextStyle(fontSize: 24))),
          ),
          title: Text(vendor.businessName, style: AppTextStyles.titleMedium),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(vendor.category, style: AppTextStyles.caption.copyWith(color: AppColors.secondary)),
              Row(
                children: [
                  const Icon(Icons.star, size: 12, color: AppColors.goldPremium),
                  const SizedBox(width: 2),
                  Text('${vendor.rating?.toStringAsFixed(1) ?? '—'} · ${vendor.location ?? ''}',
                      style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.favorite, color: AppColors.secondary),
            onPressed: onRemove,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
