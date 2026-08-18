import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// A collapsible list of actions, used for the vendor dashboard's quick
/// actions and the couple dashboard's planning tools.
///
/// Replaced a grid of equal tiles on both: six identical boxes gave every
/// action the same visual weight and filled the screen with chrome. A list
/// reads top to bottom, keeps each action on one line with its own count, and
/// folds away when the dashboard's real content matters more.
class ActionMenu extends StatelessWidget {
  /// Label on the toggle row when collapsed / expanded, e.g. "actions".
  final String noun;
  final IconData icon;
  final bool expanded;
  final VoidCallback onToggle;
  final List<ActionMenuItem> items;

  const ActionMenu({
    super.key,
    required this.noun,
    required this.icon,
    required this.expanded,
    required this.onToggle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: AppColors.forestGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        expanded ? 'Hide $noun' : 'Show $noun',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleLarge
                            .copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                    // Reflects the state rather than just decorating the row.
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // AnimatedSize over a conditional child: the divider and rows come
          // and go as one block, so the card grows and shrinks instead of
          // snapping.
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(height: 1, color: AppColors.divider),
                      ...items,
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class ActionMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  /// The count or status at the end of the row — "12 total", "4.8 avg".
  final String trailing;

  /// Optional gold pill drawn before [trailing], for things needing attention.
  final String? badge;

  /// Gold tint instead of plain — reads as a promo rather than another
  /// utility action.
  final bool promo;
  final VoidCallback onTap;

  const ActionMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
    this.badge,
    this.promo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: promo ? AppColors.goldSoft : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: promo
                      ? const Color.fromARGB(56, 201, 162, 39)
                      : AppColors.iconTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    size: 18,
                    color: promo ? AppColors.goldDeep : AppColors.forestGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleLarge
                      .copyWith(color: AppColors.textPrimary),
                ),
              ),
              // Badge *and* count, not one or the other: the badge is the
              // alert, the count is the context, and dropping the count when a
              // badge appeared hid the number exactly when it mattered most.
              if (badge != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: AppTextStyles.caption.copyWith(
                      // Ink on gold, never white — white on gold is 2.42:1.
                      color: AppColors.textOnSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  trailing,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right,
                  size: 20, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
