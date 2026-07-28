import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/constants/vendor_category_images.dart';
import '../core/services/vendor_api_service.dart' show resolveMediaUrl;
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/vendor_profile.dart';
import 'loading_shimmer.dart';

/// Vendor imagery, in priority order: the vendor's own uploaded photos (a
/// real swipeable carousel when there's more than one), else their logo,
/// else a curated stock photo for their category (see
/// [VendorCategoryImages]) — a vendor card or profile is never shown as a
/// blank icon placeholder. A stock fallback always carries a small "Sample
/// photo" badge so a couple is never led to believe it's the vendor's actual
/// work — only real uploads ever go unlabeled.
///
/// Couple-facing screens only. Vendor self-management and admin verification
/// screens must keep showing the true empty state so the vendor/admin knows
/// nothing has been uploaded yet — never use this widget there.
class VendorHeroImage extends StatefulWidget {
  final VendorProfile vendor;
  final double height;
  final int memCacheWidth;

  /// A card in a scrollable grid/list shouldn't also capture horizontal
  /// swipes — set true to render just the first image, no PageView, no dots.
  final bool single;

  /// Suppress the "Sample photo" badge for small avatar-sized usages (e.g. a
  /// 56px wishlist thumbnail) where it would have no room to render cleanly.
  final bool showBadge;

  const VendorHeroImage({
    super.key,
    required this.vendor,
    this.height = 200,
    this.memCacheWidth = 800,
    this.single = false,
    this.showBadge = true,
  });

  @override
  State<VendorHeroImage> createState() => _VendorHeroImageState();
}

class _VendorHeroImageState extends State<VendorHeroImage> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendor = widget.vendor;
    final realUrls = vendor.media.map((m) => resolveMediaUrl(m.url)).toList();
    final isSample = realUrls.isEmpty && vendor.logoUrl == null;
    final urls = realUrls.isNotEmpty
        ? realUrls
        : vendor.logoUrl != null
            ? [resolveMediaUrl(vendor.logoUrl!)]
            : VendorCategoryImages.galleryFor(vendor.category, width: widget.memCacheWidth);
    final visible = widget.single ? [urls.first] : urls;

    Widget image(String url) => CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          memCacheWidth: widget.memCacheWidth,
          placeholder: (context, url) => LoadingShimmer(
            width: double.infinity,
            height: widget.height,
            borderRadius: 0,
          ),
          errorWidget: (context, url, error) => Container(
            color: AppColors.creamDark,
            child: const Icon(Icons.image_outlined,
                color: AppColors.textHint, size: 40),
          ),
        );

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: AppColors.amber.withAlpha(20),
          child: visible.length > 1
              ? PageView.builder(
                  controller: _controller,
                  itemCount: visible.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => image(visible[i]),
                )
              : image(visible.first),
        ),
        if (visible.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                visible.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == _page ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i == _page ? Colors.white : Colors.white.withAlpha(120),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        if (isSample && widget.showBadge)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(140),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Sample photo',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
