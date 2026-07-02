import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/vendor_profile.dart';
import '../../../providers/vendor_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/constants/app_constants.dart';

const _kAllCategories = [
  'Venue',
  'Catering',
  'Photography',
  'Decor & flowers',
  'DJ & MC',
  'Transport',
];

const _kFilters = ['All', 'Under 30k', '200+ capacity', 'Verified'];

class VendorDiscoveryScreen extends ConsumerStatefulWidget {
  const VendorDiscoveryScreen({super.key});

  @override
  ConsumerState<VendorDiscoveryScreen> createState() =>
      _VendorDiscoveryScreenState();
}

class _VendorDiscoveryScreenState
    extends ConsumerState<VendorDiscoveryScreen> {
  String _selectedCategory = 'Venue';
  int _filterIndex = 0;

  @override
  Widget build(BuildContext context) {
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
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton(
                  icon: const Icon(Icons.tune_rounded, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ],
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
                    children: _kAllCategories.map((cat) {
                      final budget = catBudgets[cat];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
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
                      child: GestureDetector(
                        onTap: () => setState(() => _filterIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.forestGreen
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active
                                  ? AppColors.forestGreen
                                  : AppColors.divider,
                            ),
                          ),
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
                  '${vendors.length} ${_selectedCategory.toLowerCase()} vendors'
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
            data: (vendors) => vendors.isEmpty
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
                              'No $_selectedCategory vendors in $city yet',
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
                          child: _VendorMatchCard(
                            vendor: vendors[i],
                            matchPercent: _matchPercent(vendors[i], i),
                          ),
                        ),
                        childCount: vendors.length,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  int _matchPercent(VendorProfile v, int rank) {
    final base = (v.compositeScore * 0.7 + (v.rating ?? 0) * 6).round();
    return (base - rank * 3).clamp(70, 99);
  }

  String _filterLabel(int i) {
    final cat = _selectedCategory.toLowerCase();
    return switch (i) {
      0 => 'All ${cat}s',
      1 => 'Under 30k',
      2 => '200+ capacity',
      3 => 'Verified',
      _ => _kFilters[i],
    };
  }

}

// ── Vendor match card ─────────────────────────────────────────────────────────

class _VendorMatchCard extends ConsumerWidget {
  final VendorProfile vendor;
  final int matchPercent;

  const _VendorMatchCard({
    required this.vendor,
    required this.matchPercent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceMin = vendor.priceMin > 0
        ? '${fmtCurrency(vendor.priceMin.round())} – ${fmtAmount(vendor.priceMax.round())}'
        : null;

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
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.amber.withAlpha(20),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                ),
                child: const Center(
                  child: Icon(Icons.camera_alt_outlined,
                      size: 44, color: AppColors.amber),
                ),
              ),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded,
                          color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '$matchPercent% match',
                        style: const TextStyle(
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
                    _TagChip(label: 'Up to 300 guests', icon: Icons.people_outline_rounded),
                    if (vendor.isVerified)
                      _TagChip(
                        label: 'Verified',
                        icon: Icons.verified_user_outlined,
                        color: AppColors.success,
                        textColor: AppColors.success,
                        bgColor: AppColors.successBg,
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
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite_border_rounded,
                          color: AppColors.textSecondary, size: 22),
                      onPressed: () {},
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
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.amber,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                        child: const Text('Shortlist',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
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
