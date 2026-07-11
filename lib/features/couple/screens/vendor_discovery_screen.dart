import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/vendor_api_service.dart' show resolveMediaUrl;
import '../../../core/state/resource.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/vendor_profile.dart';
import '../../../providers/vendor_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/constants/app_constants.dart';

const _kCategoryTabs = [
  kAllVendorCategories,
  'Venue',
  'Catering',
  'Photography',
  'Decor & flowers',
  'DJ & MC',
  'Transport',
];

// 'Under 30k' and 'Verified' map to real fields (price, verification_status).
// A capacity filter isn't offered — vendor capacity isn't tracked anywhere
// in the schema, and a filter chip that silently does nothing is worse than
// not having it.
const _kFilters = ['All', 'Under 30k', 'Verified'];

class VendorDiscoveryScreen extends ConsumerStatefulWidget {
  const VendorDiscoveryScreen({super.key});

  @override
  ConsumerState<VendorDiscoveryScreen> createState() =>
      _VendorDiscoveryScreenState();
}

class _VendorDiscoveryScreenState
    extends ConsumerState<VendorDiscoveryScreen> {
  String _selectedCategory = kAllVendorCategories;
  int _filterIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (ref.read(wishlistProvider.notifier).status == ResourceStatus.initial) {
      Future.microtask(() => ref.read(wishlistProvider.notifier).loadWishlist());
    }
    final coupleProfile = ref.watch(coupleProfileProvider);
    final city = coupleProfile?.location?.split(',').first.trim() ?? 'your city';
    final vendorAsync = ref.watch(vendorListProvider(_selectedCategory));
    final totalBudget = coupleProfile?.totalBudget ?? 0.0;
    final catBudgets = Map.fromEntries(
      AppConstants.defaultBudgetAllocation.entries.map(
        (e) => MapEntry(e.key, (totalBudget * e.value).round()),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // ── Dark green header with match banner ──────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.forestGreen,
            expandedHeight: 160,
            automaticallyImplyLeading: false,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 60, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VENDOR MATCHES',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.amber,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: AppColors.amber,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.star_rounded,
                                  color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${vendorAsync.valueOrNull?.length ?? 0} vendors matched to your wedding',
                                    style: AppTextStyles.titleMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ranked by fit, budget & ratings in $city',
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.white.withAlpha(178),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Category budget tabs ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.forestGreen,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _kCategoryTabs.map((cat) {
                      final budget = catBudgets[cat];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () =>
                              setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.amber.withAlpha(40)
                                  : Colors.white.withAlpha(18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.amber
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.amber
                                        : Colors.white,
                                  ),
                                ),
                                if (budget != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    fmtCurrency(budget),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected
                                          ? AppColors.amber.withAlpha(200)
                                          : Colors.white.withAlpha(160),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

          // ── Filter pills ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_kFilters.length, (i) {
                    final active = _filterIndex == i;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Material(
                        animationDuration: const Duration(milliseconds: 150),
                        color: active
                            ? AppColors.forestGreen
                            : AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: active
                                ? AppColors.forestGreen
                                : AppColors.divider,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => setState(() => _filterIndex = i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              _filterLabel(i),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: active
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),

          // ── Match count text ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: vendorAsync.when(
                data: (vendors) => Text(
                  '${_applyFilter(vendors).length} ${_categoryNoun}vendors'
                  ' match your Flexible tier in $city',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
              ),
            ),
          ),

          // ── Vendor cards ─────────────────────────────────────────────────────
          vendorAsync.when(
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: LoadingShimmer(
                      width: double.infinity,
                      height: 280,
                      borderRadius: 16,
                    ),
                  ),
                  childCount: 3,
                ),
              ),
            ),
            error: (e, st) => SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Failed to load vendors',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            data: (allVendors) {
              final vendors = _applyFilter(allVendors);
              return vendors.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            children: [
                              const Icon(Icons.search_off_rounded,
                                  size: 48, color: AppColors.textHint),
                              const SizedBox(height: 12),
                              Text(
                                _selectedCategory == kAllVendorCategories
                                    ? 'No vendors in $city yet'
                                    : 'No $_selectedCategory vendors in $city yet',
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _VendorMatchCard(vendor: vendors[i]),
                          ),
                          childCount: vendors.length,
                        ),
                      ),
                    );
            },
          ),
        ],
      ),
    );
  }

  /// Singular-ish noun for count text, e.g. "1 venue vendors" or, when
  /// browsing every category at once, plain "4 vendors" instead of the
  /// nonsensical "4 all vendors".
  String get _categoryNoun =>
      _selectedCategory == kAllVendorCategories ? '' : '${_selectedCategory.toLowerCase()} ';

  String _filterLabel(int i) {
    if (i == 0) {
      return _selectedCategory == kAllVendorCategories
          ? 'All vendors'
          : 'All ${_selectedCategory.toLowerCase()}s';
    }
    return switch (i) {
      1 => 'Under 30k',
      2 => 'Verified',
      _ => _kFilters[i],
    };
  }

  List<VendorProfile> _applyFilter(List<VendorProfile> vendors) {
    return switch (_filterIndex) {
      1 => vendors.where((v) => v.priceMin > 0 && v.priceMin < 30000).toList(),
      2 => vendors.where((v) => v.isVerified).toList(),
      _ => vendors,
    };
  }
}

// ── Vendor match card ─────────────────────────────────────────────────────────

class _VendorMatchCard extends ConsumerWidget {
  final VendorProfile vendor;

  const _VendorMatchCard({required this.vendor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceMin = vendor.priceMin > 0
        ? '${fmtCurrency(vendor.priceMin.round())} – ${fmtAmount(vendor.priceMax.round())}'
        : null;
    final weddingDate = ref.watch(coupleProfileProvider)?.weddingDate;
    final isBookedOnWeddingDate = weddingDate != null &&
        vendor.blockedDates.contains(weddingDate.toIso8601String().split('T').first);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo area with match badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  color: AppColors.amber.withAlpha(20),
                  child: vendor.logoUrl != null
                      ? Image.network(
                          resolveMediaUrl(vendor.logoUrl!),
                          fit: BoxFit.cover,
                        )
                      : const Center(
                          child: Icon(Icons.camera_alt_outlined,
                              size: 44, color: AppColors.amber),
                        ),
                ),
              ),
              if (vendor.isVerified)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.forestGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded,
                            color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + rating
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        vendor.businessName,
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (vendor.rating != null) ...[
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppColors.amber, size: 16),
                          const SizedBox(width: 3),
                          Text(
                            vendor.rating!.toStringAsFixed(1),
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${vendor.category} · ${vendor.location ?? ''}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),

                // Chips row
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (vendor.isVerified)
                      _TagChip(
                        label: 'Verified',
                        icon: Icons.verified_user_outlined,
                        color: AppColors.success,
                        textColor: AppColors.success,
                        bgColor: AppColors.successBg,
                      ),
                    if (isBookedOnWeddingDate)
                      _TagChip(
                        label: 'Booked on your date',
                        icon: Icons.event_busy_outlined,
                        color: AppColors.warning,
                        textColor: AppColors.warning,
                        bgColor: AppColors.warningBg,
                      ),
                  ],
                ),

                if (priceMin != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    priceMin,
                    style: AppTextStyles.priceTag.copyWith(
                      color: AppColors.amber,
                      fontSize: 16,
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                // Action row
                Builder(builder: (context) {
                  final isWishlisted = ref.watch(wishlistProvider).contains(vendor.id);
                  return Row(
                    children: [
                      IconButton(
                        tooltip: isWishlisted ? 'Remove from wishlist' : 'Add to wishlist',
                        icon: Icon(
                          isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isWishlisted ? AppColors.error : AppColors.textSecondary,
                          size: 22,
                        ),
                        onPressed: () => ref.read(wishlistProvider.notifier).toggle(vendor.id),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              context.push('/couple/vendors/${vendor.id}'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.divider),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            foregroundColor: AppColors.textPrimary,
                          ),
                          child: const Text('View profile',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => ref.read(wishlistProvider.notifier).toggle(vendor.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.amber,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                          ),
                          child: Text(isWishlisted ? 'Shortlisted' : 'Shortlist',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

// ── Tag chip ──────────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color bgColor;

  const _TagChip({
    required this.label,
    required this.icon,
    this.color = AppColors.textSecondary,
    this.textColor = AppColors.textSecondary,
    this.bgColor = AppColors.creamDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
