import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/inherited/shell_scaffold.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/vendor_profile.dart';
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
    final picked = ref.watch(pickedVendorsProvider);
    final couple = ref.watch(coupleProfileProvider);
    final location = couple?.location;
    final hasLocation = location != null && location.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Find Vendors'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Open menu',
            onPressed: () =>
                ShellScaffold.of(ctx)?.scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.tune_outlined), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) =>
                  ref.read(vendorSearchQueryProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Search vendors...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Location match banner
          if (hasLocation)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 15, color: AppColors.info),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Showing best vendors near $location',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.info),
                      ),
                    ),
                    const Icon(Icons.auto_awesome,
                        size: 14, color: AppColors.goldPremium),
                    const SizedBox(width: 4),
                    Text('AI matched',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.goldPremium,
                            fontWeight: FontWeight.w600)),
                  ],
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
                        ref
                            .read(selectedCategoryProvider.notifier)
                            .state = cat,
                    selectedColor:
                        AppColors.secondary.withAlpha(38),
                    checkmarkColor: AppColors.secondary,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Vendor picker dropdown
          const _VendorPickerDropdown(),
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
                  VendorCardShimmer(),
                  VendorCardShimmer(),
                  VendorCardShimmer(),
                  VendorCardShimmer(),
                ],
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 8),
                    Text('Failed to load vendors',
                        style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              data: (vendors) {
                if (vendors.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔍',
                            style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('No $category vendors yet',
                            style: AppTextStyles.headlineMedium),
                        Text('Check back soon!',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
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
                      isPicked: picked.contains(vendor.id),
                      rank: i + 1,
                      onTap: () =>
                          context.push('/couple/vendors/${vendor.id}'),
                      onWishlistToggle: () => ref
                          .read(wishlistProvider.notifier)
                          .toggle(vendor.id),
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

// ── Vendor picker dropdown ──────────────────────────────────────────────────

class _VendorPickerDropdown extends ConsumerStatefulWidget {
  const _VendorPickerDropdown();

  @override
  ConsumerState<_VendorPickerDropdown> createState() =>
      _VendorPickerDropdownState();
}

class _VendorPickerDropdownState extends ConsumerState<_VendorPickerDropdown> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedCategoryProvider, (prev, _) {
      if (_expanded) setState(() => _expanded = false);
    });

    final category = ref.watch(selectedCategoryProvider);
    final vendorsAsync = ref.watch(vendorListProvider(category));
    final picked = ref.watch(pickedVendorsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: vendorsAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (err, _) => const SizedBox.shrink(),
        data: (vendors) {
          final pickedCount =
              vendors.where((v) => picked.contains(v.id)).length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header button
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: pickedCount > 0
                          ? AppColors.secondary.withValues(alpha: 0.5)
                          : AppColors.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        pickedCount > 0
                            ? Icons.check_circle
                            : Icons.checklist_outlined,
                        size: 18,
                        color: pickedCount > 0
                            ? AppColors.secondary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pickedCount > 0
                              ? '$pickedCount vendor${pickedCount > 1 ? 's' : ''} picked in $category'
                              : 'Pick a $category vendor',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: pickedCount > 0
                                ? AppColors.secondary
                                : AppColors.textSecondary,
                            fontWeight: pickedCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              // Expanded list
              if (_expanded)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < vendors.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                        _VendorPickerTile(
                          vendor: vendors[i],
                          isPicked: picked.contains(vendors[i].id),
                          onToggle: () => ref
                              .read(pickedVendorsProvider.notifier)
                              .toggle(vendors[i].id),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _VendorPickerTile extends StatelessWidget {
  final VendorProfile vendor;
  final bool isPicked;
  final VoidCallback onToggle;

  const _VendorPickerTile({
    required this.vendor,
    required this.isPicked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isPicked ? AppColors.secondary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isPicked ? AppColors.secondary : AppColors.divider,
                  width: 2,
                ),
              ),
              child: isPicked
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.businessName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight:
                          isPicked ? FontWeight.w600 : FontWeight.normal,
                      color: isPicked
                          ? AppColors.secondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    vendor.location ?? '',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.star, size: 12, color: AppColors.goldPremium),
            const SizedBox(width: 2),
            Text(
              vendor.rating?.toStringAsFixed(1) ?? '—',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
