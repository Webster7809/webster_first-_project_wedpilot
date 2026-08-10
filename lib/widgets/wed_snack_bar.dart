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
  Duration duration = const Duration(seconds: 3),
}) {
  final colors = {
    SnackType.success: AppColors.success,
    SnackType.error: AppColors.error,
    SnackType.warning: AppColors.warning,
    SnackType.info: AppColors.info,
  };
  final icons = {
    SnackType.success: Icons.check_circle_outlined,
    SnackType.error: Icons.error_outlined,
    SnackType.warning: Icons.warning_amber_outlined,
    SnackType.info: Icons.info_outlined,
  };

  final messenger = ScaffoldMessenger.of(context);
  // ScaffoldMessenger *queues* snack bars and plays them back to back, so
  // booking three vendors in a row used to leave a bar on screen for three
  // times its duration — indistinguishable from one that never dismisses.
  // Only the newest message is ever worth showing, so drop whatever is on
  // screen first.
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
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
      duration: duration,
      action: actionLabel != null && onAction != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              // Dismiss as soon as the action is taken — leaving the bar up
              // after an Undo invites tapping it twice.
              onPressed: () {
                messenger.hideCurrentSnackBar();
                onAction();
              },
            )
          : null,
    ),
  );
}
