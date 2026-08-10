import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'wed_button.dart';

/// Shown when something failed and retrying is the way out.
///
/// Same shape as [WedEmptyState] on purpose — a failure should not feel like a
/// different kind of screen, only a different message.
class WedErrorState extends StatelessWidget {
  /// Caller-supplied explanation of what went wrong.
  final String message;
  final VoidCallback? onRetry;

  /// Defaults to a connectivity icon; pass [Icons.error_outlined] for failures
  /// that aren't network-related.
  final IconData icon;
  final String title;
  final String retryLabel;

  /// Banner layout instead of the full-screen block — for errors that sit
  /// inside a form or a card, where a 64px icon would shove the primary action
  /// off screen.
  final bool compact;

  const WedErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.wifi_off,
    this.title = 'Something went wrong',
    this.retryLabel = 'Try again',
  }) : compact = false;

  /// Inline error banner. Used for form and field-level failures.
  const WedErrorState.inline({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outlined,
    this.retryLabel = 'Try again',
  })  : compact = true,
        title = '';

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.error),
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
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              WedButton(
                label: retryLabel,
                onPressed: onRetry,
                shrinkWrap: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            WedButton(
              label: retryLabel,
              variant: WedButtonVariant.ghost,
              onPressed: onRetry,
              shrinkWrap: true,
              height: 32,
              fontSize: 13,
            ),
          ],
        ],
      ),
    );
  }
}
