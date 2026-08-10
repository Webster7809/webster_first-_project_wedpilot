import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_text_styles.dart';

/// The surface every piece of content sits on.
///
/// Carries its own very soft warm shadow rather than a Material elevation —
/// the intent is that a card reads as *lifted*, never as *dropped*. When
/// [onTap] is supplied the whole card scales down slightly while held.
class WedCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double borderRadius;

  const WedCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = 20,
  });

  @override
  State<WedCard> createState() => _WedCardState();
}

class _WedCardState extends State<WedCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);

    final card = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppColors.surface,
        borderRadius: radius,
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.all(16),
        child: widget.child,
      ),
    );

    if (widget.onTap == null) return card;

    // GestureDetector alone gives screen readers nothing to announce, so the
    // card has to declare itself tappable.
    return Semantics(
      button: true,
      container: true,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: card,
        ),
      ),
    );
  }
}

class BudgetCategoryCard extends StatelessWidget {
  final String categoryName;
  final String categoryIcon;
  final double allocated;
  final double spent;
  final String currency;
  final VoidCallback? onTap;

  const BudgetCategoryCard({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.allocated,
    required this.spent,
    required this.currency,
    this.onTap,
  });

  double get percent => allocated > 0 ? (spent / allocated).clamp(0, 1) : 0;

  Color get barColor {
    if (percent >= 1.0) return AppColors.budgetRed;
    if (percent >= 0.9) return AppColors.budgetAmber;
    return AppColors.budgetGreen;
  }

  @override
  Widget build(BuildContext context) {
    return WedCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // The category "icon" is an emoji glyph, so it is sized through
              // the type scale rather than an IconTheme.
              Text(categoryIcon, style: AppTextStyles.subheading),
              const SizedBox(width: 8),
              Expanded(
                child: Text(categoryName, style: AppTextStyles.titleMedium),
              ),
              if (percent >= 0.9)
                Icon(
                  percent >= 1.0 ? Icons.warning : Icons.info_outlined,
                  size: 16,
                  color: percent >= 1.0 ? AppColors.budgetRed : AppColors.budgetAmber,
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Theme.of(context).colorScheme.outlineVariant.withAlpha(102),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$currency ${spent.toStringAsFixed(0)} spent',
                  style: AppTextStyles.caption),
              Text('of $currency ${allocated.toStringAsFixed(0)}',
                  style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
