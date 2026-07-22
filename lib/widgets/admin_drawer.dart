import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/logout_dialog.dart';
import '../providers/auth_provider.dart';

/// Admin-shell equivalent of [AppDrawer]/[VendorDrawer] — mobile-only (the
/// desktop layout already has a permanent sidebar, see `_AdminSidebar` in
/// `admin_shell.dart`). Replaces the mobile bottom nav's 4 tabs
/// (Dashboard/Users/Vendors/Analytics) plus the standalone logout icon that
/// used to float over the mobile layout.
class AdminDrawer extends ConsumerWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final displayName = user?.name ?? 'Admin';
    final email = user?.email ?? '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Drawer(
      child: Column(
        children: [
          // A plain Container (not DrawerHeader) so it sizes to its content
          // instead of DrawerHeader's own imposed minimum height, which
          // clipped this header's bottom line once a subtitle was added.
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: AppColors.forestGreen),
            child: SafeArea(
              bottom: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withAlpha(128),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      displayName,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withAlpha(204),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/admin/dashboard');
                  },
                ),
                _DrawerItem(
                  icon: Icons.people_rounded,
                  label: 'Users',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/admin/users');
                  },
                ),
                _DrawerItem(
                  icon: Icons.verified_rounded,
                  label: 'Vendors',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/admin/vendors');
                  },
                ),
                _DrawerItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Analytics',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/admin/analytics');
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Divider(),
                ),

                _DrawerItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/settings');
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Divider(),
                ),

                _DrawerItem(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  iconColor: AppColors.error,
                  labelColor: AppColors.error,
                  onTap: () {
                    Navigator.of(context).pop();
                    confirmLogout(context, ref);
                  },
                ),

                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'Wedpilot v1.0.0',
                      style: AppTextStyles.caption.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(97),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.secondary, size: 22),
      title: Text(
        label,
        style: AppTextStyles.titleMedium.copyWith(
          color: labelColor ?? Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      horizontalTitleGap: 8,
    );
  }
}
