import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/inherited/shell_scaffold.dart';
import '../core/router/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/logout_dialog.dart';
import '../widgets/admin_drawer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AdminShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 800) {
      return _DesktopLayout(navigationShell: widget.navigationShell, ref: ref);
    }
    return _MobileLayout(
      navigationShell: widget.navigationShell,
      ref: ref,
      scaffoldKey: _scaffoldKey,
    );
  }
}

// ── Desktop: sidebar + content ─────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final WidgetRef ref;
  const _DesktopLayout({required this.navigationShell, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Row(
        children: [
          _AdminSidebar(
            currentIndex: navigationShell.currentIndex,
            onBranch: (i) => navigationShell.goBranch(
              i,
              initialLocation: i == navigationShell.currentIndex,
            ),
            ref: ref,
          ),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

// ── Mobile: drawer nav ─────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final WidgetRef ref;
  final GlobalKey<ScaffoldState> scaffoldKey;
  const _MobileLayout({
    required this.navigationShell,
    required this.ref,
    required this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      scaffoldKey: scaffoldKey,
      child: Scaffold(
        key: scaffoldKey,
        drawer: const AdminDrawer(),
        body: navigationShell,
      ),
    );
  }
}

// ── Sidebar ────────────────────────────────────────────────────────────────────

class _AdminSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onBranch;
  final WidgetRef ref;
  const _AdminSidebar({
    required this.currentIndex,
    required this.onBranch,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.forestGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          const SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Row(
                children: [
                  _LogoIcon(),
                  SizedBox(width: 10),
                  Text(
                    'WedPilot',
                    style: TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sections
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _SidebarSection(
                  label: 'OVERVIEW',
                  children: [
                    _SidebarItem(
                      icon: Icons.dashboard_outlined,
                      label: 'Dashboard',
                      index: 0,
                      currentIndex: currentIndex,
                      onTap: onBranch,
                    ),
                  ],
                ),
                _SidebarSection(
                  label: 'PEOPLE',
                  children: [
                    _SidebarItem(
                      icon: Icons.people_outline,
                      label: 'Couples',
                      index: 1,
                      currentIndex: currentIndex,
                      onTap: onBranch,
                    ),
                    _SidebarItem(
                      icon: Icons.verified_outlined,
                      label: 'Vendors',
                      index: 2,
                      currentIndex: currentIndex,
                      onTap: onBranch,
                    ),
                  ],
                ),
                _SidebarSection(
                  label: 'PLATFORM',
                  children: [
                    _SidebarRouteItem(
                      icon: Icons.flag_outlined,
                      label: 'Reported listings',
                      route: AppRoutes.adminModeration,
                      context: context,
                    ),
                    _SidebarRouteItem(
                      icon: Icons.category_outlined,
                      label: 'Categories',
                      route: AppRoutes.adminCategories,
                      context: context,
                    ),
                    _SidebarRouteItem(
                      icon: Icons.article_outlined,
                      label: 'Invitation templates',
                      route: AppRoutes.adminInvitationTemplates,
                      context: context,
                    ),
                    _SidebarItem(
                      icon: Icons.bar_chart_outlined,
                      label: 'Match algorithm',
                      index: 3,
                      currentIndex: currentIndex,
                      onTap: onBranch,
                    ),
                  ],
                ),
                _SidebarSection(
                  label: 'SYSTEM',
                  children: [
                    _SidebarRouteItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      route: '/settings',
                      context: context,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Log out
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            child: TextButton.icon(
              onPressed: () => confirmLogout(context, ref),
              icon: const Icon(Icons.logout, color: Colors.white54, size: 18),
              label: const Text(
                'Log out',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoIcon extends StatelessWidget {
  const _LogoIcon();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.amber,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.favorite, color: Colors.white, size: 20),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _SidebarSection({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white38,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(10),
        splashColor: AppColors.amber.withAlpha(50),
        highlightColor: AppColors.amber.withAlpha(25),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withAlpha(20) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? Border(left: BorderSide(color: AppColors.amber, width: 3))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? AppColors.amber : Colors.white70,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? AppColors.amber : Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarRouteItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final BuildContext context;

  const _SidebarRouteItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.context,
  });

  @override
  Widget build(BuildContext _) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(10),
        splashColor: AppColors.amber.withAlpha(50),
        highlightColor: AppColors.amber.withAlpha(25),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.white70),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
