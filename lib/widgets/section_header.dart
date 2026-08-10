import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'gold_rule.dart';

/// Title for a section of a screen, with the brand's signature 48px gold
/// hairline beneath it.
///
/// That rule is the one piece of pure decoration in the system, and it earns
/// its place by doing all the section-boundary work — which is why it appears
/// here and nowhere else. Do not reuse the hairline in other widgets.
class WedSectionHeader extends StatelessWidget {
  final String title;

  /// Label for the trailing action. When null no action is rendered.
  final String? actionLabel;
  final VoidCallback? onSeeAll;

  const WedSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppTextStyles.subheading),
              const SizedBox(height: 6),
              const GoldRule(),
            ],
          ),
        ),
        if (actionLabel != null)
          Flexible(
            child: TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.button.copyWith(
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Legacy name kept for existing call sites. Prefer [WedSectionHeader].
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => WedSectionHeader(
        title: title,
        actionLabel: actionLabel,
        onSeeAll: onAction,
      );
}
