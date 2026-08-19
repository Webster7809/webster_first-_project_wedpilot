import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/vendor_category_images.dart';
import '../../../core/state/resource.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/vendor_profile.dart';
import '../../../providers/vendor_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/gold_rule.dart';
import '../../../widgets/hamburger_menu_button.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../widgets/typeahead_field.dart';
import '../../../widgets/vendor_hero_image.dart';
import '../../../widgets/wed_card.dart';
import '../../../widgets/wed_empty_state.dart';
import '../../../widgets/wed_snack_bar.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/constants/app_constants.dart';

// Derived from AppConstants.vendorCategories (the single source of truth,
// also used by the onboarding wizard's category picker) so this can't drift
// out of sync and silently drop a category again.
const _kCategoryTabs = [kAllVendorCategories, ...AppConstants.vendorCategories];

// 'Under 30k' and 'Verified' map to real fields (price, verification_status).
// 'Fits my guests' maps to VendorService.maxGuests via
// VendorProfile.canServeGuestCount, checked against the couple's saved
// guestCount — see _applyFilter, which only offers this chip when a guest
// count is actually on file.
const _kFilters = ['All', 'Under 30k', 'Verified', 'Fits my guests'];

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
  String _committedSearch = '';

  @override
  Widget build(BuildContext context) {
    if (ref.read(wishlistProvider.notifier).status == ResourceStatus.initial) {
      Future.microtask(() => ref.read(wishlistProvider.notifier).loadWishlist());
    }
    final coupleProfile = ref.watch(coupleProfileProvider);
    final city = coupleProfile?.location?.split(',').first.trim() ?? 'your city';
    // 'Fits my guests' is only meaningful once the couple has a guest count
    // on file — a chip that silently does nothing (or filters against a
    // number that doesn't exist) is worse than not offering it.
    final guestCount = coupleProfile?.guestCount;
    final activeFilters = guestCount != null && guestCount > 0
        ? _kFilters
        : _kFilters.sublist(0, _kFilters.length - 1);
    if (_filterIndex >= activeFilters.length) {
      _filterIndex = 0;
    }
    final vendorAsync = _committedSearch.isEmpty
        ? ref.watch(vendorListProvider(_selectedCategory))
        : ref.watch(vendorSearchResultsProvider(
            (category: _selectedCategory, search: _committedSearch),
          ));
    final totalBudget = coupleProfile?.totalBudget ?? 0.0;
    final catBudgets = Map.fromEntries(
      AppConstants.defaultBudgetAllocation.entries.map(
        (e) => MapEntry(e.key, (totalBudget * e.value).round()),
      ),
    );
    // Shown once for the category being browsed rather than under every tab.
    final selectedBudget = catBudgets[_selectedCategory];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Dark green header with match banner ──────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.forestGreen,
            expandedHeight: 160,
            automaticallyImplyLeading: false,
            leading: const HamburgerMenuButton(color: Colors.white),
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
                          // Gold on the forest header — 4.99:1.
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // The headline carries the count on its own — the boxed
                      // banner that used to sit here was chrome between the
                      // couple and the first photograph.
                      Text(
                        '${vendorAsync.valueOrNull?.length ?? 0} vendors matched',
                        style: AppTextStyles.displaySmall
                            .copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ranked by fit, budget and ratings in $city',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white.withAlpha(190)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Vendor search ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.forestGreen,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              // This bar is always forest green with a white search box,
              // regardless of app theme — so the field is forced to the light
              // input theme too. Otherwise dark mode keeps the white fill (by
              // design, for contrast against the green) but swaps the typed
              // text to the dark theme's light-on-dark color, making it
              // invisible on the still-white box.
              child: Theme(
                data: AppTheme.light,
                child: TypeaheadField<VendorProfile>(
                  hint: 'Search vendors by name...',
                  prefixIcon: Icons.search,
                  fillColor: Colors.white,
                  debounceDuration: const Duration(milliseconds: 300),
                  suggestionsCallback: (query) async {
                    if (query.isEmpty) {
                      if (_committedSearch.isNotEmpty && mounted) {
                        setState(() => _committedSearch = '');
                      }
                      return <VendorProfile>[];
                    }
                    final results = await ref.read(
                      vendorSearchResultsProvider(
                        (category: _selectedCategory, search: query),
                      ).future,
                    );
                    if (mounted) setState(() => _committedSearch = query);
                    return results;
                  },
                  displayStringForOption: (v) => v.businessName,
                  onSelected: (v) =>
                      setState(() => _committedSearch = v.businessName),
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
                  // One line, one label per category. The per-category budget
                  // that used to sit under every tab now appears once, for the
                  // selected category, in the count line below — same
                  // information, a fraction of the noise.
                  child: Row(
                    children: _kCategoryTabs.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.gold
                                    : Colors.white.withAlpha(20),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.chip),
                              ),
                              child: Text(
                                cat,
                                style: AppTextStyles.labelMedium.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  // Ink on the gold fill, white on the forest.
                                  color: isSelected
                                      ? AppColors.textOnSecondary
                                      : Colors.white,
                                ),
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

          // ── Result count + filter entry point ────────────────────────────────
          // The four filters used to sit here as a permanent second pill row.
          // They now live behind one control that states what is active, so
          // the first vendor photograph is one row closer to the top.
          SliverConstrainedCrossAxis(
            maxExtent: AppDimensions.contentMaxWidth,
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: vendorAsync.when(
                        data: (vendors) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_applyFilter(vendors).length} ${_categoryNoun}vendors in $city',
                              style: AppTextStyles.titleMedium.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                            ),
                            if (selectedBudget != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Your $_selectedCategory budget: ${fmtCurrency(selectedBudget)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                              ),
                            ],
                          ],
                        ),
                        loading: () => const LoadingShimmer(
                            width: 180, height: 16, borderRadius: 4),
                        error: (e, st) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _FilterButton(
                      label: _filterIndex == 0
                          ? 'Filter'
                          : _filterLabel(_filterIndex, guestCount),
                      isActive: _filterIndex != 0,
                      onTap: () => _openFilterSheet(activeFilters, guestCount),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Vendor cards ─────────────────────────────────────────────────────
          // Constrained and centred so cards stay a readable width on a
          // laptop/desktop window instead of stretching edge to edge — a
          // no-op on phone widths, which are already under the cap.
          SliverConstrainedCrossAxis(
            maxExtent: AppDimensions.contentMaxWidth,
            sliver: vendorAsync.when(
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
                        child: WedEmptyState(
                          icon: Icons.search_off,
                          title: 'No vendors found',
                          message: _selectedCategory == kAllVendorCategories
                              ? 'No vendors in $city yet'
                              : 'No $_selectedCategory vendors in $city yet',
                          imageUrl: VendorCategoryImages.galleryFor('Venue')[0],
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
          ),
        ],
      ),
    );
  }

  /// Filters live in a sheet rather than a permanent pill row: only one can be
  /// active at a time, so a whole row of them was spending the screen's most
  /// valuable space to show four options the couple mostly isn't using.
  Future<void> _openFilterSheet(List<String> filters, int? guestCount) async {
    final chosen = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Text('Filter vendors',
                    style: AppTextStyles.displaySmall
                        .copyWith(color: colors.onSurface)),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: GoldRule(),
              ),
              ...List.generate(filters.length, (i) {
                final selected = i == _filterIndex;
                return ListTile(
                  onTap: () => Navigator.of(sheetContext).pop(i),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  minVerticalPadding: 14,
                  title: Text(
                    _filterLabel(i, guestCount),
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: colors.onSurface,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: selected
                      ? Icon(Icons.check, color: colors.primary)
                      : null,
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (chosen != null && mounted) setState(() => _filterIndex = chosen);
  }

  /// Singular-ish noun for count text, e.g. "1 venue vendors" or, when
  /// browsing every category at once, plain "4 vendors" instead of the
  /// nonsensical "4 all vendors".
  String get _categoryNoun =>
      _selectedCategory == kAllVendorCategories ? '' : '${_selectedCategory.toLowerCase()} ';

  String _filterLabel(int i, int? guestCount) {
    if (i == 0) {
      return _selectedCategory == kAllVendorCategories
          ? 'All vendors'
          : 'All ${_selectedCategory.toLowerCase()}s';
    }
    return switch (i) {
      1 => 'Under 30k',
      2 => 'Verified',
      3 => guestCount != null ? 'Fits $guestCount guests' : 'Fits my guests',
      _ => _kFilters[i],
    };
  }

  List<VendorProfile> _applyFilter(List<VendorProfile> vendors) {
    final guestCount = ref.read(coupleProfileProvider)?.guestCount;
    return switch (_filterIndex) {
      1 => vendors.where((v) => v.priceMin > 0 && v.priceMin < 30000).toList(),
      2 => vendors.where((v) => v.isVerified).toList(),
      3 when guestCount != null && guestCount > 0 =>
        vendors.where((v) => v.canServeGuestCount(guestCount)).toList(),
      _ => vendors,
    };
  }
}

// ── Vendor match card ─────────────────────────────────────────────────────────

class _VendorMatchCard extends ConsumerWidget {
  final VendorProfile vendor;

  const _VendorMatchCard({required this.vendor});

  Future<void> _toggleWishlist(BuildContext context, WidgetRef ref) async {
    final error = await ref.read(wishlistProvider.notifier).toggle(vendor.id);
    if (error != null && context.mounted) {
      showWedSnackBar(context, error, type: SnackType.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceMin = vendor.priceMin > 0
        ? '${fmtCurrency(vendor.priceMin.round())} – ${fmtAmount(vendor.priceMax.round())}'
        : null;
    final weddingDate = ref.watch(coupleProfileProvider)?.weddingDate;
    final isBookedOnWeddingDate = weddingDate != null &&
        vendor.blockedDates.contains(weddingDate.toIso8601String().split('T').first);

    final isWishlisted = ref.watch(wishlistProvider).contains(vendor.id);

    // The card is the primary action: tapping it opens the profile. The old
    // layout had three controls competing — a heart, "View profile", and
    // "Shortlist" — where the heart and "Shortlist" toggled the same wishlist.
    return WedCard(
      padding: EdgeInsets.zero,
      borderRadius: AppRadius.card,
      onTap: () => context.push('/couple/vendors/${vendor.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Photograph, doing the selling ──────────────────────────────────
          ClipRRect(
            borderRadius: AppRadius.top(AppRadius.card),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VendorHeroImage(
                    vendor: vendor,
                    height: 220,
                    memCacheWidth: 720,
                    single: true,
                  ),
                  // Scrim: the name sits on the photo, so it needs a
                  // predictable ground regardless of what the vendor uploaded.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xCC000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          vendor.businessName,
                          style: AppTextStyles.headlineLarge
                              .copyWith(color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [vendor.category, vendor.location]
                              .whereType<String>()
                              .where((s) => s.isNotEmpty)
                              .join(' · '),
                          style: AppTextStyles.bodySmall
                              .copyWith(color: Colors.white.withAlpha(205)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (vendor.isVerified)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _OverlayBadge(
                        icon: Icons.verified,
                        label: 'Verified',
                      ),
                    ),
                  if (vendor.rating != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _OverlayBadge(
                        icon: Icons.star,
                        label: vendor.rating!.toStringAsFixed(1),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Quiet metadata ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (priceMin != null)
                        Text(priceMin,
                            style: AppTextStyles.dataMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface))
                      else
                        Text('Price on request',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      if (vendor.maxGuestCapacity != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Seats up to ${vendor.maxGuestCapacity} guests',
                          style: AppTextStyles.bodySmall.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                      if (isBookedOnWeddingDate) ...[
                        const SizedBox(height: 6),
                        _TagChip(
                          label: 'Booked on your date',
                          icon: Icons.event_busy_outlined,
                          color: AppColors.warning,
                          textColor: AppColors.warning,
                          bgColor: AppColors.warningBg,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isWishlisted
                      ? 'Remove ${vendor.businessName} from wishlist'
                      : 'Save ${vendor.businessName} to wishlist',
                  icon: Icon(
                    isWishlisted ? Icons.favorite : Icons.favorite_outlined,
                    color: isWishlisted
                        ? AppColors.error
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  onPressed: () => _toggleWishlist(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overlay badge ─────────────────────────────────────────────────────────────

/// A pill sitting on top of a photograph. Deliberately dark rather than gold:
/// over an unknown image only a solid dark ground guarantees the white label
/// stays readable.
class _OverlayBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _OverlayBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.forestGreen.withAlpha(230),
        borderRadius: AppRadius.bfull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.gold, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

// ── Filter button ─────────────────────────────────────────────────────────────

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: isActive ? AppColors.forestGreen : colors.surface,
      borderRadius: AppRadius.bfull,
      child: InkWell(
        borderRadius: AppRadius.bfull,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44, maxWidth: 190),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: AppRadius.bfull,
            border: Border.all(
              color: isActive ? AppColors.forestGreen : colors.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_outlined,
                  size: 16,
                  color: isActive ? Colors.white : colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isActive ? Colors.white : colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
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
