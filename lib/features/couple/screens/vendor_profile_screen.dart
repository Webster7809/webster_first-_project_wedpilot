import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/messaging_api_service.dart';
import '../../../core/services/vendor_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/vendor_profile.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vendor_provider.dart';
import '../../../widgets/booking_action_button.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../widgets/photo_viewer_screen.dart';
import '../../../widgets/vendor_hero_image.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_snack_bar.dart';
import '../../../core/constants/vendor_category_images.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/share_helper.dart';

class VendorProfileScreen extends ConsumerWidget {
  final String vendorId;
  const VendorProfileScreen({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorAsync = ref.watch(vendorDetailProvider(vendorId));

    return vendorAsync.when(
      loading: () => _buildSkeleton(context),
      error: (e, _) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
  bool _messaging = false;

  Future<void> _toggleWishlist(String vendorId) async {
    final error = await ref.read(wishlistProvider.notifier).toggle(vendorId);
    if (error != null && mounted) {
      showWedSnackBar(context, error, type: SnackType.error);
    }
  }

  // The only way a couple could reach a vendor conversation used to be
  // opening an existing one from the Messages tab — nothing anywhere let
  // them start one. This is that missing entry point: right from the
  // profile they're already looking at, before ever sending a formal
  // inquiry.
  Future<void> _messageVendor(String vendorId) async {
    final token = ref.read(authProvider.notifier).accessToken;
    if (token == null) {
      showWedSnackBar(context, 'Not signed in.', type: SnackType.error);
      return;
    }
    setState(() => _messaging = true);
    try {
      final convo = await MessagingApiService.instance.startConversation(token, vendorId);
      if (!mounted) return;
      context.push('/couple/messages/${convo.id}');
    } on MessagingApiException catch (e) {
      if (!mounted) return;
      showWedSnackBar(context, e.message, type: SnackType.error);
    } finally {
      if (mounted) setState(() => _messaging = false);
    }
  }

  Future<void> _reportPhoto(VendorMedia media) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ReportReasonSheet(),
    );
    if (reason == null || !mounted) return;

    final token = ref.read(authProvider.notifier).accessToken;
    if (token == null) {
      showWedSnackBar(context, 'Not signed in.', type: SnackType.error);
      return;
    }
    try {
      await VendorApiService.instance.reportMedia(token, media.id, reason: reason);
      if (!mounted) return;
      showWedSnackBar(context, "Thanks — we'll review this photo.", type: SnackType.success);
    } on VendorApiException catch (e) {
      if (!mounted) return;
      showWedSnackBar(context, e.message, type: SnackType.error);
    } catch (_) {
      if (!mounted) return;
      showWedSnackBar(context, 'Could not report this photo. Please try again.', type: SnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendor = widget.vendor;
    final isWishlisted = ref.watch(wishlistProvider).contains(vendor.id);
    final priceStr = vendor.priceMin > 0
        ? '${fmtCurrency(vendor.priceMin.round())} – ${fmtAmount(vendor.priceMax.round())}'
        : null;
    final maxGuestCapacity = vendor.maxGuestCapacity;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  // Real photo carousel when the vendor has uploads, else a
                  // labeled category-relevant sample (see VendorHeroImage).
                  VendorHeroImage(vendor: vendor, height: 260, memCacheWidth: 800),
                  // Back button
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 16,
                    child: _OverlayButton(
                      icon: Icons.chevron_left,
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
                          onTap: () => shareWithFallback(
                            context,
                            text: [
                              'Check out ${vendor.businessName} on WedPilot',
                              if (vendor.category.isNotEmpty) vendor.category,
                              if (vendor.location != null) vendor.location!,
                            ].join(' — '),
                            subject: vendor.businessName,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _OverlayButton(
                          icon: isWishlisted
                              ? Icons.favorite
                              : Icons.favorite_outlined,
                          onTap: () => _toggleWishlist(vendor.id),
                          iconColor: isWishlisted
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
                // Centres the page at AppDimensions.contentMaxWidth. Without
                // this the whole profile — description, packages, reviews —
                // ran the full width of a laptop window as one very long
                // line, which is what made it read as stretched.
                padding: EdgeInsets.fromLTRB(
                  AppDimensions.gutter(MediaQuery.sizeOf(context).width),
                  20,
                  AppDimensions.gutter(MediaQuery.sizeOf(context).width),
                  120,
                ),
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
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_outlined,
                                    color: AppColors.goldDeep, size: 14),
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

                    // Badges row — public CRS-derived stats only; no reviews,
                    // no reviewer identity, no written comments ever appear here.
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (vendor.isVerified)
                          _Pill(
                            label: 'Verified vendor',
                            icon: Icons.verified_user_outlined,
                            color: AppColors.success,
                            bgColor: AppColors.successBg,
                          ),
                        if (vendor.feedbackCount > 0)
                          _Pill(
                            label: 'Based on ${vendor.feedbackCount} completed bookings',
                            icon: Icons.star_outlined,
                            color: AppColors.amber,
                            bgColor: AppColors.creamDark,
                          ),
                        if (vendor.respondsInMinutes != null)
                          _Pill(
                            label: 'Responds in ~${_formatMinutes(vendor.respondsInMinutes!)}',
                            icon: Icons.bolt_outlined,
                            color: AppColors.info,
                            bgColor: AppColors.info.withAlpha(20),
                          ),
                        if (vendor.weddingsCompleted > 0)
                          _Pill(
                            label: '${vendor.weddingsCompleted} weddings completed',
                            icon: Icons.celebration_outlined,
                            color: AppColors.forestGreen,
                            bgColor: AppColors.forestGreen.withAlpha(15),
                          ),
                        if (vendor.recommendRate != null)
                          _Pill(
                            label: '${(vendor.recommendRate! * 100).round()}% recommend',
                            icon: Icons.thumb_up_alt_outlined,
                            color: AppColors.forestGreen,
                            bgColor: AppColors.forestGreen.withAlpha(15),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.coupleFeedbackNew, extra: vendor.id),
                      icon: const Icon(Icons.rate_review_outlined, size: 16),
                      label: const Text('Rate this vendor'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.forestGreen,
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),

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
                                      color: AppColors.primary,
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
                      const SizedBox(height: 16),
                    ],

                    // Guest capacity card
                    if (maxGuestCapacity != null) ...[
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
                                    'GUEST CAPACITY',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Can serve up to: $maxGuestCapacity guests',
                                    style: AppTextStyles.priceTag.copyWith(
                                      color: AppColors.forestGreen,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.groups_outlined,
                                color: AppColors.textSecondary, size: 24),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Contact details
                    if (vendor.phone != null || vendor.website != null) ...[
                      Text('Contact',
                          style: AppTextStyles.headlineSmall.copyWith(
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      if (vendor.phone != null)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                          onTap: () =>
                              launchUrl(Uri.parse('tel:${vendor.phone}')),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.forestGreen.withAlpha(15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.call_outlined,
                                      color: AppColors.forestGreen, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    vendor.phone!,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.forestGreen,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: AppColors.textSecondary, size: 18),
                              ],
                            ),
                          ),
                          ),
                        ),
                      if (vendor.website != null)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                          onTap: () {
                            final url = vendor.website!.startsWith('http')
                                ? vendor.website!
                                : 'https://${vendor.website!}';
                            launchUrl(Uri.parse(url));
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withAlpha(15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.language_outlined,
                                      color: AppColors.info, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    vendor.website!,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.info,
                                      decoration: TextDecoration.underline,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: AppColors.textSecondary, size: 18),
                              ],
                            ),
                          ),
                          ),
                        ),
                      const SizedBox(height: 14),
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
                    if (vendor.media.isEmpty) ...[
                      Text(
                        "${vendor.businessName} hasn't uploaded photos yet — showing sample "
                        '${vendor.category} photos below.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      Builder(builder: (context) {
                        final thumbs = VendorCategoryImages.galleryFor(
                            vendor.category,
                            width: 450,
                            vendorId: vendor.id);
                        final fullRes = VendorCategoryImages.galleryFor(
                            vendor.category,
                            width: 1600,
                            vendorId: vendor.id);
                        return GridView.count(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: thumbs.asMap().entries.map((entry) {
                            final i = entry.key;
                            final url = entry.value;
                            return GestureDetector(
                              onTap: () => PhotoViewerScreen.open(
                                context,
                                urls: fullRes,
                                initialIndex: i,
                                heroLabel: 'Sample ${vendor.category} photo',
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 450,
                                  placeholder: (context, url) => Container(
                                    color: AppColors.amber.withAlpha(20),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: AppColors.amber.withAlpha(20),
                                    child: const Icon(Icons.broken_image_outlined,
                                        color: AppColors.goldDeep, size: 24),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }),
                    ] else
                      Builder(builder: (context) {
                        final shown = vendor.media.take(6).toList();
                        final fullRes =
                            shown.map((m) => resolveMediaUrl(m.url)).toList();
                        return GridView.count(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: shown.asMap().entries.map((entry) {
                          final i = entry.key;
                          final m = entry.value;
                          return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  GestureDetector(
                                    onTap: () => PhotoViewerScreen.open(
                                      context,
                                      urls: fullRes,
                                      initialIndex: i,
                                      heroLabel: '${vendor.businessName} photo',
                                    ),
                                    child: CachedNetworkImage(
                                      imageUrl: resolveMediaUrl(m.url),
                                      fit: BoxFit.cover,
                                      memCacheWidth: 450,
                                      placeholder: (context, url) => Container(
                                        color: AppColors.amber.withAlpha(20),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: AppColors.amber.withAlpha(20),
                                        child: const Icon(Icons.broken_image_outlined,
                                            color: AppColors.goldDeep, size: 24),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Material(
                                      color: Colors.black.withAlpha(140),
                                      shape: const CircleBorder(),
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: () => _reportPhoto(m),
                                        child: const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Icon(Icons.flag_outlined,
                                              size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                        }).toList(),
                        );
                      }),
                    const SizedBox(height: 24),

                    // Details
                    Text('Details',
                        style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.forestGreen,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
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
        // The bar itself stays full-bleed (it's a surface), but its contents
        // line up with the page above rather than stretching to the edges.
        padding: EdgeInsets.fromLTRB(
            AppDimensions.gutter(MediaQuery.sizeOf(context).width),
            12,
            AppDimensions.gutter(MediaQuery.sizeOf(context).width),
            MediaQuery.of(context).padding.bottom + 12),
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
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: _messaging
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.chat_bubble_outline,
                          color: AppColors.forestGreen),
                      tooltip: 'Message ${vendor.businessName}',
                      onPressed: () => _messageVendor(vendor.id),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BookingActionButton(vendor: vendor, height: 52),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: WedButton(
                label: isWishlisted ? 'Shortlisted' : 'Shortlist',
                variant: WedButtonVariant.secondary,
                onPressed: () => _toggleWishlist(vendor.id),
              ),
            ),
          ],
        ),
      ),
    );
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
    return Material(
      color: Colors.black.withAlpha(60),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}

// ── Formatting ────────────────────────────────────────────────────────────────

String _formatMinutes(double minutes) {
  if (minutes < 60) return '${minutes.round()} min';
  final hours = minutes / 60;
  if (hours < 24) return '${hours.round()} hr';
  return '${(hours / 24).round()} d';
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
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportReasonSheet extends StatefulWidget {
  const _ReportReasonSheet();

  @override
  State<_ReportReasonSheet> createState() => _ReportReasonSheetState();
}

class _ReportReasonSheetState extends State<_ReportReasonSheet> {
  static const _reasons = [
    'Inappropriate content',
    'Misleading or fake photo',
    'Copyright violation',
    'Spam or scam',
    'Other',
  ];
  String _selected = _reasons.first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Material(
        color: AppColors.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Report Photo', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 4),
              Text(
                "Let us know what's wrong with this photo.",
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _selected,
                onChanged: (v) => setState(() => _selected = v ?? _selected),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _reasons
                      .map((r) => RadioListTile<String>(
                            value: r,
                            title: Text(r, style: AppTextStyles.bodyMedium),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.forestGreen,
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              WedButton(
                label: 'Submit Report',
                onPressed: () => Navigator.pop(context, _selected),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
