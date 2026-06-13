import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

enum WedButtonVariant { primary, secondary, ghost, destructive }

class WedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final WedButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  /// Explicit width. When null the button expands to fill its parent
  /// (constrained by [maxWidth] if provided).
  final double? width;

  /// Maximum width — useful for forms on large screens. Defaults to 480.
  final double maxWidth;

  final double height;

  const WedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = WedButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.maxWidth = 480,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == WedButtonVariant.primary ? Colors.white : AppColors.secondary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label, style: AppTextStyles.buttonText.copyWith(color: _foreground)),
            ],
          );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width != null ? width! : maxWidth,
          minHeight: height,
          maxHeight: height,
        ),
        child: SizedBox(
          width: width ?? double.infinity,
          height: height,
          child: switch (variant) {
            WedButtonVariant.primary => ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: child,
              ),
            WedButtonVariant.secondary => OutlinedButton(
                onPressed: isLoading ? null : onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: child,
              ),
            WedButtonVariant.ghost => TextButton(
                onPressed: isLoading ? null : onPressed,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: child,
              ),
            WedButtonVariant.destructive => ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: child,
              ),
          },
        ),
      ),
    );
  }

  Color get _foreground => switch (variant) {
        WedButtonVariant.primary || WedButtonVariant.destructive => Colors.white,
        _ => AppColors.secondary,
      };
}
