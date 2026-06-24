import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/vendor_profile.dart';
import '../../../providers/vendor_provider.dart';
import '../../../widgets/loading_shimmer.dart';

class VendorProfileScreen extends ConsumerWidget {
  final String vendorId;
  const VendorProfileScreen({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorAsync = ref.watch(vendorDetailProvider(vendorId));

    return vendorAsync.when(
      loading: () => _buildSkeleton(context),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(
          child: Text('Failed to load vendor',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ),
      ),
      data: (vendor) => _VendorProfileBody(vendor: vendor),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.creamDark,
            expandedHeight: 260,
            pinned: false,
            automaticallyImplyLeading: false,
            flexibleSpace: const FlexibleSpaceBar(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LoadingShimmer(width: 200, height: 28, borderRadius: 8),
                  const SizedBox(height: 8),
                  const LoadingShimmer(width: 140, height: 14, borderRadius: 6),
                  const SizedBox(height: 20),
                  LoadingShimmer(
                      width: double.infinity, height: 72, borderRadius: 12),
                  const SizedBox(height: 20),
                  const LoadingShimmer(width: 120, height: 18),
                  const SizedBox(height: 8),
                  LoadingShimmer(
                      width: double.infinity, height: 80, borderRadius: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorProfileBody extends ConsumerStatefulWidget {
  final VendorProfile vendor;
  const _VendorProfileBody({required this.vendor});

  @override
  ConsumerState<_VendorProfileBody> createState() => _VendorProfileBodyState();
}

class _VendorProfileBodyState extends ConsumerState<_VendorProfileBody> {
  bool _isWishlisted = false;

  @override
  Widget build(BuildContext context) {
    final vendor = widget.vendor;
    final priceStr = vendor.priceMin > 0
        ? 'ZMW ${_fmt(vendor.priceMin.round())} – ${_fmt(vendor.priceMax.round())}'
        : null;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // ── Photo carousel area ──────────────────────────────────────────────
          SliverAppBar(
            pinned: false,
            expandedHeight: 260,
            backgroundColor: AppColors.creamDark,
            automaticallyImplyLeading: false,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo placeholder
                  Container(
                    color: AppColors.amber.withAlpha(20),
                    child: const Center(
                      child: Icon(Icons.villa_outlined,
                          size: 56, color: AppColors.amber),
                    ),
                  ),
                  // Carousel dots
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) => Container(
                        width: i == 0 ? 20 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i == 0
                              ? Colors.white
                              : Colors.white.withAlpha(120),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )),
                    ),
                  ),
                  // Back button
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 16,
                    child: _OverlayButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: () => context.pop(),
                    ),
                  ),
                  // Share + heart
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    right: 16,
                    child: Row(
                      children: [
                        _OverlayButton(
                          icon: Icons.share_outlined,
                          onTap: () {},
                        ),
                        const SizedBox(width: 8),
                        _OverlayButton(
                          icon: _isWishlisted
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          onTap: () =>
                              setState(() => _isWishlisted = !_isWishlisted),
                          iconColor: _isWishlisted
                              ? AppColors.error
                              : Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Content card ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
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
                            style: AppTextStyles.displaySmall.copyWith(
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (vendor.rating != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_outline_rounded,
                                    color: AppColors.amber, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  vendor.rating!.toStringAsFixed(1),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vendor.category} · ${vendor.location ?? ''}',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),

                    // Pills row
                    Wrap(
                      spacing: 8,
                      children: [
                        if (vendor.isVerified)
                          _Pill(
                            label: 'Verified vendor',
                            icon: Icons.verified_user_outlined,
                            color: AppColors.success,
                            bgColor: AppColors.successBg,
                          ),
                        if (vendor.reviewCount > 0)
                          _Pill(
                            label: '${vendor.reviewCount} reviews',
                            icon: Icons.star_outline_rounded,
                            color: AppColors.amber,
                            bgColor: AppColors.creamDark,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Match banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.forestGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppColors.amber, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '96% match for your wedding',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Fits your Flexible tier & 80–200 guest range',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white.withAlpha(178),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // About
                    Text('About this venue',
                        style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.forestGreen,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      vendor.description ??
                          'A beautiful ${vendor.category.toLowerCase()} for your special day.',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary, height: 1.6),
                    ),
                    const SizedBox(height: 24),

                    // Price range card
                    if (priceStr != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.creamDark,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PRICE RANGE',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.amber,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    priceStr,
                                    style: AppTextStyles.priceTag.copyWith(
                                      color: AppColors.forestGreen,
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.credit_card_outlined,
                                color: AppColors.textSecondary, size: 24),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Photos grid
                    Row(
                      children: [
                        Text('Photos',
                            style: AppTextStyles.headlineSmall.copyWith(
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(
                        vendor.media.isEmpty ? 3 : vendor.media.length.clamp(0, 6),
                        (_) => Container(
                          decoration: BoxDecoration(
                            color: AppColors.amber.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.camera_alt_outlined,
                              color: AppColors.amber, size: 24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Details
                    Text('Details',
                        style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.forestGreen,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _DetailRow(
                        icon: Icons.people_outline_rounded,
                        label: 'Up to 300 guests'),
                    _DetailRow(
                        icon: Icons.verified_user_outlined,
                        label: vendor.isVerified ? 'Verified vendor' : 'Pending verification',
                        color: vendor.isVerified ? AppColors.success : AppColors.textSecondary),
                    if (vendor.location != null)
                      _DetailRow(
                          icon: Icons.location_on_outlined,
                          label: vendor.location!),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Fixed bottom bar
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text('Send inquiry',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.divider, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: AppColors.textPrimary,
                ),
                child: const Text('Shortlist',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) {
      final thousands = n ~/ 1000;
      final rem = n % 1000;
      return rem == 0
          ? '$thousands,000'
          : '$thousands,${rem.toString().padLeft(3, '0')}';
    }
    return n.toString();
  }
}

// ── Overlay circle button ─────────────────────────────────────────────────────

class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _OverlayButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(60),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

// ── Pill badge ────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _Pill({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DetailRow({
    required this.icon,
    required this.label,
    this.color = AppColors.amber,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
