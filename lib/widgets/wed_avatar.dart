import 'package:flutter/material.dart';
import '../core/services/vendor_api_service.dart' show resolveMediaUrl;
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class WedAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;

  const WedAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 24,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(resolveMediaUrl(imageUrl!)),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      child: Text(
        _initials,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.secondary,
          fontSize: radius * 0.6,
        ),
      ),
    );
  }
}
