import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/vendor_provider.dart';
import '../../../widgets/wed_card.dart';
import '../../../widgets/loading_shimmer.dart';

class VendorDiscoveryScreen extends ConsumerWidget {
  const VendorDiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(selectedCategoryProvider);
    final vendorsAsync = ref.watch(vendorListProvider(category));
    final wishlist = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Find Vendors'),
        actions: [
          IconButton(icon: const Icon(Icons.tune_outlined), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) => ref.read(vendorSearchQueryProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Search vendors...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Category tabs
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: AppConstants.vendorCategories.length,
              itemBuilder: (_, i) {
                final cat = AppConstants.vendorCategories[i];
                final icon = AppConstants.vendorCategoryIcons[i];
                final isSelected = cat == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text('$icon $cat'),
                    selected: isSelected,
                    onSelected: (_) =>
                        ref.read(selectedCategoryProvider.notifier).state = cat,
                    selectedColor: AppColors.secondary.withOpacity(0.15),
                    checkmarkColor: AppColors.secondary,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Vendor grid
          Expanded(
            child: vendorsAsync.when(
              loading: () => GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(16),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
                children: const [
                  VendorCardShimmer(), VendorCardShimmer(),
                  VendorCardShimmer(), VendorCardShimmer(),
                ],
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 8),
                    Text('Failed to load vendors', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              data: (vendors) {
                if (vendors.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔍', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('No $category vendors yet', style: AppTextStyles.headlineMedium),
                        Text('Check back soon!',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: vendors.length,
                  itemBuilder: (_, i) {
                    final vendor = vendors[i];
                    return VendorCard(
                      vendor: vendor,
                      isWishlisted: wishlist.contains(vendor.id),
                      rank: i + 1,
                      onTap: () => context.push('/couple/vendors/${vendor.id}'),
                      onWishlistToggle: () =>
                          ref.read(wishlistProvider.notifier).toggle(vendor.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
