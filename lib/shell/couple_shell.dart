import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/inherited/shell_scaffold.dart';
import '../core/theme/app_colors.dart';

class CoupleShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const CoupleShell({super.key, required this.navigationShell});

  @override
  State<CoupleShell> createState() => _CoupleShellState();
}

class _CoupleShellState extends State<CoupleShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      scaffoldKey: _scaffoldKey,
      child: Scaffold(
        key: _scaffoldKey,
        body: widget.navigationShell,
        bottomNavigationBar: _CoupleNavBar(
          currentIndex: widget.navigationShell.currentIndex,
          onTap: _onTabSelected,
        ),
      ),
    );
  }

  void _onTabSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

class _CoupleNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _CoupleNavBar({required this.currentIndex, required this.onTap});

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
              _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', index: 0, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.search_outlined, activeIcon: Icons.search_rounded, label: 'Vendors', index: 1, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.credit_card_outlined, activeIcon: Icons.credit_card_rounded, label: 'Budget', index: 2, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.mail_outline_rounded, activeIcon: Icons.mail_rounded, label: 'Invite', index: 3, currentIndex: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile', index: 4, currentIndex: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
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
