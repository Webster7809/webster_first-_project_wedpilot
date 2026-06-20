import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final coupleProfile = ref.watch(coupleProfileProvider);

    final displayName = user?.name ?? 'Guest';
    final email = user?.email ?? '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final subtitle = coupleProfile?.weddingDate != null
        ? 'Wedding: ${_formatDate(coupleProfile!.weddingDate!)}'
        : email;

    return Drawer(
      child: Column(
        children: [
          // ── Drawer Header ────────────────────────────────────────
          DrawerHeader(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFFF06292)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Avatar circle
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(64),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(128), width: 2),
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
                    style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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

          // ── Navigation Items ─────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/couple/dashboard');
                  },
                ),
                _DrawerItem(
                  icon: Icons.mail_rounded,
                  label: 'Invitations',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/couple/invitations');
                  },
                ),
                _DrawerItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Budget',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/couple/budget');
                  },
                ),
                _DrawerItem(
                  icon: Icons.storefront_rounded,
                  label: 'Vendors',
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/couple/vendors');
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
                _DrawerItem(
                  icon: Icons.info_outline_rounded,
                  label: 'About',
                  onTap: () {
                    Navigator.of(context).pop();
                    showAboutDialog(
                      context: context,
                      applicationName: 'Wedpilot',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.secondary,
                        size: 36,
                      ),
                      applicationLegalese: '© 2024 Wedpilot. All rights reserved.\n'
                          'Your perfect wedding planning companion.',
                    );
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
                    _confirmLogout(context, ref);
                  },
                ),

                // ── Footer inside list so it never overflows ──────
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'Wedpilot v1.0.0',
                      style: AppTextStyles.caption.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(97),
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

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authProvider.notifier).logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ── Single drawer row ──────────────────────────────────────────────────────────

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
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.secondary,
        size: 22,
      ),
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
