import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_text_styles.dart';

enum WedButtonVariant {
  /// Forest green fill, white label. The single primary action on a screen.
  primary,

  /// Kept for existing call sites — renders identically to [primary] now that
  /// the primary fill is forest green.
  primaryDark,

  /// Transparent with a green hairline border. Secondary actions.
  secondary,

  /// No fill, no border, forest label. Tertiary / inline actions.
  ///
  /// The label was gold until gold was measured against cream: 2.12:1 at full
  /// strength, and only 4.25:1 even at [AppColors.goldDeep], which still misses
  /// AA at this button's 15px label. Gold stays on the hairline, not the text.
  ghost,

  /// Soft red fill, red label. Destructive actions stay quiet until confirmed.
  danger,

  /// Legacy name for [danger].
  destructive,

  /// Solid gold fill, ink label. For CTAs that need to stand out as the app's
  /// accent rather than the primary forest green (e.g. inquiry/shortlist/save
  /// actions that were previously raw amber ElevatedButtons).
  ///
  /// The label is ink, never white — white on gold is 2.42:1.
  accent,

  /// Solid success-green fill, white label. For explicit confirm/accept
  /// actions (e.g. accepting a booking or lead).
  success,
}

class WedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final WedButtonVariant variant;
  final bool isLoading;

  /// Optional leading widget, separated from the label by an 8px gap.
  final Widget? icon;

  /// Optional trailing widget, separated from the label by an 8px gap.
  final Widget? trailingIcon;

  /// Explicit width. When null the button expands to fill its parent
  /// (constrained by [maxWidth]), unless [shrinkWrap] is set.
  final double? width;

  /// Maximum width — useful for forms on large screens. Defaults to 480.
  final double maxWidth;

  /// Sizes the button to its content instead of filling the available width.
  final bool shrinkWrap;

  final double height;
  final double borderRadius;

  /// Overrides the label size for compact in-card buttons. Leave null to use
  /// the design system's button style unchanged.
  final double? fontSize;

  const WedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = WedButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.width,
    this.maxWidth = 480,
    this.shrinkWrap = false,
    this.height = 52,
    this.borderRadius = AppRadius.button,
    this.fontSize,
  });

  Color get _background => switch (variant) {
    WedButtonVariant.primary ||
    WedButtonVariant.primaryDark => AppColors.primary,
    WedButtonVariant.danger ||
    WedButtonVariant.destructive => AppColors.errorSoft,
    WedButtonVariant.accent => AppColors.amber,
    WedButtonVariant.success => AppColors.success,
    _ => Colors.transparent,
  };

  Color get _foreground => switch (variant) {
    WedButtonVariant.primary || WedButtonVariant.primaryDark => Colors.white,
    WedButtonVariant.secondary || WedButtonVariant.ghost => AppColors.primary,
    WedButtonVariant.danger || WedButtonVariant.destructive => AppColors.error,
    // Ink on gold (6.44:1), white on success green (6.42:1) — a gold fill can
    // never take a white label.
    WedButtonVariant.accent => AppColors.textOnSecondary,
    WedButtonVariant.success => Colors.white,
  };

  BorderSide? get _border => variant == WedButtonVariant.secondary
      ? const BorderSide(color: AppColors.primary, width: 1.5)
      : null;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final radius = BorderRadius.circular(borderRadius);
    final foreground = enabled ? _foreground : _foreground.withAlpha(110);
    // A transparent fill has no alpha to dim: Colors.transparent is
    // 0x00000000, so withAlpha(90) turns it into 35% *black* — which is how a
    // disabled secondary/ghost button (e.g. "Resend in 60s" on the verify
    // screen) rendered as a grey slab. Only fills that are actually painted
    // get dimmed.
    final background = enabled || _background == Colors.transparent
        ? _background
        : _background.withAlpha(90);

    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                // _foreground is already the correct on-fill color per variant,
                // including ink on the gold accent fill.
                color: _foreground,
              ),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  IconTheme.merge(
                    data: IconThemeData(color: foreground, size: 18),
                    child: icon!,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: AppTextStyles.button.copyWith(
                      color: foreground,
                      fontSize: fontSize,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  IconTheme.merge(
                    data: IconThemeData(color: foreground, size: 18),
                    child: trailingIcon!,
                  ),
                ],
              ],
            ),
    );

    final button = Material(
      color: background,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: _border != null
                ? Border.fromBorderSide(
                    enabled ? _border! : _border!.copyWith(color: foreground),
                  )
                : null,
          ),
          child: Container(
            height: height,
            padding: EdgeInsets.symmetric(
              horizontal: variant == WedButtonVariant.ghost ? 16 : 24,
            ),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );

    if (shrinkWrap) {
      return IntrinsicWidth(child: button);
    }

    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width ?? maxWidth,
          minHeight: height,
          maxHeight: height,
        ),
        child: SizedBox(width: width ?? double.infinity, child: button),
      ),
    );
  }
}
