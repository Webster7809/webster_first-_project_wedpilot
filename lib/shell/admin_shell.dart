import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../widgets/shell_nav_item.dart';
import '../providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const AdminShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 800) {
      return _DesktopLayout(navigationShell: navigationShell, ref: ref);
    }
    return _MobileLayout(navigationShell: navigationShell, ref: ref);
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

// ── Mobile: bottom nav ─────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final WidgetRef ref;
  const _MobileLayout({required this.navigationShell, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.forestGreen,
          border: Border(top: BorderSide(color: AppColors.vendorIndigo)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                ShellNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard', index: 0, currentIndex: navigationShell.currentIndex, onTap: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex), inactiveColor: Colors.white60, labelFontSize: 10),
                ShellNavItem(icon: Icons.people_outline, activeIcon: Icons.people_rounded, label: 'Users', index: 1, currentIndex: navigationShell.currentIndex, onTap: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex), inactiveColor: Colors.white60, labelFontSize: 10),
                ShellNavItem(icon: Icons.verified_outlined, activeIcon: Icons.verified_rounded, label: 'Vendors', index: 2, currentIndex: navigationShell.currentIndex, onTap: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex), inactiveColor: Colors.white60, labelFontSize: 10),
                ShellNavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Analytics', index: 3, currentIndex: navigationShell.currentIndex, onTap: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex), inactiveColor: Colors.white60, labelFontSize: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ── Sidebar ────────────────────────────────────────────────────────────────────

class _AdminSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onBranch;
  final WidgetRef ref;
  const _AdminSidebar({required this.currentIndex, required this.onBranch, required this.ref});

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
                _SidebarSection(label: 'OVERVIEW', children: [
                  _SidebarItem(icon: Icons.dashboard_outlined, label: 'Dashboard', index: 0, currentIndex: currentIndex, onTap: onBranch),
                ]),
                _SidebarSection(label: 'PEOPLE', children: [
                  _SidebarItem(icon: Icons.people_outline, label: 'Couples', index: 1, currentIndex: currentIndex, onTap: onBranch),
                  _SidebarItem(icon: Icons.verified_outlined, label: 'Vendors', index: 2, currentIndex: currentIndex, onTap: onBranch),
                ]),
                _SidebarSection(label: 'PLATFORM', children: [
                  _SidebarRouteItem(icon: Icons.flag_outlined, label: 'Reported listings', route: '/admin/moderation', context: context),
                  _SidebarStaticItem(icon: Icons.category_outlined, label: 'Categories'),
                  _SidebarStaticItem(icon: Icons.article_outlined, label: 'Invitation templates'),
                  _SidebarItem(icon: Icons.bar_chart_outlined, label: 'Match algorithm', index: 3, currentIndex: currentIndex, onTap: onBranch),
                ]),
                _SidebarSection(label: 'SYSTEM', children: [
                  _SidebarRouteItem(icon: Icons.settings_outlined, label: 'Settings', route: '/settings', context: context),
                ]),
              ],
            ),
          ),

          // Log out
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            child: TextButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout, color: Colors.white54, size: 18),
              label: const Text('Log out', style: TextStyle(color: Colors.white54, fontSize: 14)),
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
              style: GoogleFonts.inter(
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
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive ? Border(left: BorderSide(color: AppColors.amber, width: 3)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? AppColors.amber : Colors.white70),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.amber : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarStaticItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SidebarStaticItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext _) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _SidebarRouteItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final BuildContext context;

  const _SidebarRouteItem({required this.icon, required this.label, required this.route, required this.context});

  @override
  Widget build(BuildContext _) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white70),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
