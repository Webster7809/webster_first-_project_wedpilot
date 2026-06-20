import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';

class VendorShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const VendorShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _VendorNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class _VendorNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _VendorNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _VNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Dashboard', index: 0, currentIndex: currentIndex, onTap: onTap),
              _VNavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'Listings', index: 1, currentIndex: currentIndex, onTap: onTap),
              _VNavItem(icon: Icons.mail_outline_rounded, activeIcon: Icons.mail_rounded, label: 'Inquiries', index: 2, currentIndex: currentIndex, onTap: onTap),
              _VNavItem(icon: Icons.star_outline_rounded, activeIcon: Icons.star_rounded, label: 'Reviews', index: 3, currentIndex: currentIndex, onTap: onTap),
              _VNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Account', index: 4, currentIndex: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _VNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _VNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: isActive ? AppColors.amber : AppColors.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.amber : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
