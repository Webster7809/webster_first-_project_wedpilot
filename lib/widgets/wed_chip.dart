import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Semantic colouring for a chip that reports a state rather than offering a
/// choice. [WedChipTone.neutral] is the selectable filter chip.
enum WedChipTone { neutral, gold, success, error }

/// Category / tag / status chip. Selection is a colour change rather than a
/// shape change, so a row of chips never reflows as the user taps through them.
class WedChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final WedChipTone tone;

  /// Tighter padding and a smaller label, for chips that sit inside a card or
  /// over an image rather than in a filter row.
  final bool dense;

  /// Fills the available width and stands 48px tall, for chips used as a
  /// segmented choice (e.g. the couple/vendor role picker) rather than a tag.
  final bool expand;

  const WedChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.tone = WedChipTone.neutral,
    this.dense = false,
    this.expand = false,
  });

  Color get _background => switch (tone) {
        WedChipTone.neutral =>
          isSelected ? AppColors.accentSoft : AppColors.surfaceAlt,
        WedChipTone.gold => AppColors.accentSoft,
        WedChipTone.success => AppColors.successBg,
        WedChipTone.error => AppColors.errorBg,
      };

  Color get _border => switch (tone) {
        WedChipTone.neutral =>
          isSelected ? AppColors.accent : Colors.transparent,
        WedChipTone.gold => AppColors.accent,
        WedChipTone.success || WedChipTone.error => Colors.transparent,
      };

  Color get _foreground => switch (tone) {
        WedChipTone.neutral =>
          isSelected ? AppColors.primary : AppColors.textMuted,
        WedChipTone.gold => AppColors.primary,
        WedChipTone.success => AppColors.success,
        WedChipTone.error => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    final selectedWeight =
        tone == WedChipTone.neutral && !isSelected ? FontWeight.w400 : FontWeight.w600;

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: expand ? double.infinity : null,
      height: expand ? 48 : null,
      alignment: expand ? Alignment.center : null,
      padding: switch ((dense, expand)) {
        (true, _) => const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        (_, true) => const EdgeInsets.symmetric(horizontal: 16),
        _ => const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      },
      decoration: BoxDecoration(
        color: _background,
        borderRadius: radius,
        border: Border.all(color: _border, width: 1),
      ),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        style: (dense ? AppTextStyles.caption : AppTextStyles.bodySmall)
            .copyWith(color: _foreground, fontWeight: selectedWeight),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );

    if (onTap == null) return chip;

    return InkWell(onTap: onTap, borderRadius: radius, child: chip);
  }
}
