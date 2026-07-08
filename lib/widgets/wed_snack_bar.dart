import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

enum SnackType { success, error, warning, info }

void showWedSnackBar(
  BuildContext context,
  String message, {
  SnackType type = SnackType.info,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final colors = {
    SnackType.success: AppColors.success,
    SnackType.error: AppColors.error,
    SnackType.warning: AppColors.warning,
    SnackType.info: AppColors.info,
  };
  final icons = {
    SnackType.success: Icons.check_circle_outline,
    SnackType.error: Icons.error_outline,
    SnackType.warning: Icons.warning_amber_outlined,
    SnackType.info: Icons.info_outline,
  };

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icons[type], color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor: colors[type],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
      action: actionLabel != null && onAction != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction,
            )
          : null,
    ),
  );
}
