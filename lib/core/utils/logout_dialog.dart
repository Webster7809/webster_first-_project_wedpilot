import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../theme/app_colors.dart';

/// Shared "Are you sure you want to log out?" confirmation, used by every
/// role's drawer/sidebar so the prompt and behavior stay identical across
/// Couple, Vendor, and Admin.
void confirmLogout(BuildContext context, WidgetRef ref) {
  // Grab the notifier NOW, not inside the dialog's button. The caller is
  // usually a drawer item that closes its drawer before showing this dialog;
  // once the close animation finishes the drawer subtree is unmounted, and
  // reading through its (now-disposed) `ref` when the user finally confirms
  // throws instead of logging out. The notifier itself lives in the provider
  // container and outlives the drawer.
  final auth = ref.read(authProvider.notifier);
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
            auth.logout();
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Log Out'),
        ),
      ],
    ),
  );
}
