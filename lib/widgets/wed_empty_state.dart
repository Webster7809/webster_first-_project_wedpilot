import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'loading_shimmer.dart';
import 'wed_button.dart';

/// Shown when a list or screen has nothing in it yet.
///
/// One icon (or photo), one sentence explaining why it's empty, and at most
/// one action — the empty state is where a user is most likely to be lost,
/// so it stays the quietest thing on screen.
class WedEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  /// When null, no action button is rendered.
  final String? ctaLabel;
  final VoidCallback? onCtaTap;

  /// Optional curated photo shown as a circular image instead of a plain
  /// icon — the "empty" moment doesn't have to feel bare. Falls back to
  /// [icon] on a load error, so a network hiccup never leaves a blank gap.
  final String? imageUrl;

  const WedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.ctaLabel,
    this.onCtaTap,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (imageUrl != null)
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: 104,
                  height: 104,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 300),
                  placeholder: (_, _) =>
                      const LoadingShimmer(width: 104, height: 104, borderRadius: 52),
                  errorWidget: (_, _, _) =>
                      Icon(icon, size: 64, color: AppColors.goldDeep),
                ),
              )
            else
              Icon(icon, size: 64, color: AppColors.goldDeep),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.subheading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            if (ctaLabel != null) ...[
              const SizedBox(height: 24),
              WedButton(
                label: ctaLabel!,
                onPressed: onCtaTap,
                shrinkWrap: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
