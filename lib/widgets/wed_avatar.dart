import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/services/vendor_api_service.dart' show resolveMediaUrl;
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

enum WedAvatarSize {
  small(32),
  medium(48),
  large(72);

  const WedAvatarSize(this.diameter);
  final double diameter;
}

/// Profile image inside a thin gold ring. Falls back to the person's initials
/// on forest green — the same treatment whether the image is missing, still
/// loading, or failed to load.
class WedAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;

  /// Preset diameter. Overrides [radius] when supplied.
  final WedAvatarSize? size;

  /// Explicit radius, for the sizes that predate [WedAvatarSize].
  final double radius;

  const WedAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size,
    this.radius = 24,
  });

  double get _diameter => size?.diameter ?? radius * 2;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      width: _diameter,
      height: _diameter,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
      child: ClipOval(
        child: hasImage
            ? CachedNetworkImage(
                imageUrl: resolveMediaUrl(imageUrl!),
                fit: BoxFit.cover,
                width: _diameter,
                height: _diameter,
                // Decode at 3x the drawn size (enough for the densest screen)
                // rather than at full upload resolution — a list of avatars on
                // a mid-range device otherwise decodes megabytes it never
                // shows. Only the width is capped so cover keeps its aspect.
                memCacheWidth: (_diameter * 3).round(),
                imageBuilder: (context, provider) => Semantics(
                  label: '$name profile photo',
                  image: true,
                  child: Ink.image(image: provider, fit: BoxFit.cover),
                ),
                placeholder: (_, _) => _fallback,
                errorWidget: (_, _, _) => _fallback,
              )
            : _fallback,
      ),
    );
  }

  Widget get _fallback => Container(
        color: AppColors.primary,
        alignment: Alignment.center,
        child: Text(
          _initials,
          style: AppTextStyles.subheading.copyWith(
            color: AppColors.primary,
            fontSize: _diameter * 0.36,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
