import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/inherited/shell_scaffold.dart';
import '../core/theme/app_colors.dart';
import '../widgets/app_drawer.dart';

class CoupleShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const CoupleShell({super.key, required this.navigationShell});

  @override
  State<CoupleShell> createState() => _CoupleShellState();
}

class _CoupleShellState extends State<CoupleShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _tabCount = 5; // Home, Invitations, Budget, Vendors, Profile

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      scaffoldKey: _scaffoldKey,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(),
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (index) {
            if (index == _tabCount) {
              context.push('/settings');
            } else {
              _onTabSelected(index);
            }
          },
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.5),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.mail_outline_rounded),
              selectedIcon: Icon(Icons.mail_rounded),
              label: 'Invitations',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Plan',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search),
              label: 'Vendors',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
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
