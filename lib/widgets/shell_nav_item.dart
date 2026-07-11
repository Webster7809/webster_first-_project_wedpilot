import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ShellNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color activeColor;
  final Color inactiveColor;
  final double labelFontSize;

  const ShellNavItem({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.activeColor = AppColors.amber,
    this.inactiveColor = AppColors.textSecondary,
    this.labelFontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    return Expanded(
      child: Tooltip(
        message: label,
        // Material + InkWell instead of a bare GestureDetector so tapping
        // actually shows a visible splash/highlight — a plain GestureDetector
        // gives zero tap feedback. splashColor/highlightColor are pinned to
        // activeColor so the ripple stays visible on both light (couple/
        // vendor) and dark (admin) nav bar backgrounds.
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(index),
            splashColor: activeColor.withAlpha(60),
            highlightColor: activeColor.withAlpha(30),
            child: SizedBox.expand(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive ? activeIcon : icon,
                    size: 22,
                    color: isActive ? activeColor : inactiveColor,
                  ),
                  const SizedBox(height: 3),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      // FittedBox shrinks the label to whatever height the
                      // row actually has left, instead of overflowing it,
                      // when a large accessibility text-scale setting
                      // inflates the label past the bottom nav's fixed
                      // height.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: labelFontSize,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                            color: isActive ? activeColor : inactiveColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
