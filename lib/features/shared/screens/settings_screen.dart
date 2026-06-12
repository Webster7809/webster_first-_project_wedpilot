import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../widgets/wed_snack_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _Section(title: 'Account', children: [
            _SettingTile(icon: Icons.person_outline, title: 'Edit Profile', onTap: () {}),
            _SettingTile(icon: Icons.email_outlined, title: 'Email', subtitle: user?.email ?? '', onTap: () {}),
            _SettingTile(icon: Icons.lock_outline, title: 'Change Password', onTap: () {}),
            _SettingTile(icon: Icons.people_outline, title: 'Partner Access', onTap: () {}),
          ]),
          _Section(title: 'Notifications', children: [
            _SettingToggle(icon: Icons.notifications_outlined, title: 'Push Notifications', value: true, onChanged: (_) {}),
            _SettingToggle(icon: Icons.email_outlined, title: 'Email Notifications', value: true, onChanged: (_) {}),
            _SettingToggle(icon: Icons.sms_outlined, title: 'SMS Notifications', value: false, onChanged: (_) {}),
          ]),
          _Section(title: 'Privacy & Data', children: [
            _SettingTile(icon: Icons.download_outlined, title: 'Export My Data', onTap: () => showWedSnackBar(context, 'Data export requested!', type: SnackType.success)),
            _SettingTile(icon: Icons.cookie_outlined, title: 'Cookie Preferences', onTap: () {}),
            _SettingTile(icon: Icons.policy_outlined, title: 'Privacy Policy', onTap: () {}),
            _SettingTile(icon: Icons.description_outlined, title: 'Terms of Service', onTap: () {}),
          ]),
          _Section(title: 'Support', children: [
            _SettingTile(icon: Icons.help_outline, title: 'Help & FAQ', onTap: () => context.push('/help')),
            _SettingTile(icon: Icons.star_outline, title: 'Rate the App', onTap: () {}),
            _SettingTile(icon: Icons.info_outline, title: 'App Version', subtitle: '1.0.0 (build 1)', onTap: null),
          ]),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                ref.read(budgetProvider.notifier).clearBudget();
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: () {},
              child: Text('Delete Account', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Text(title, style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
        ),
        Material(
          color: AppColors.surface,
          child: Column(children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1) const Divider(height: 1, indent: 52),
            ],
          ]),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingTile({required this.icon, required this.title, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.secondary, size: 22),
      title: Text(title, style: AppTextStyles.bodyMedium),
      subtitle: subtitle != null ? Text(subtitle!, style: AppTextStyles.caption) : null,
      trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary) : null,
      onTap: onTap,
    );
  }
}

class _SettingToggle extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingToggle({required this.icon, required this.title, required this.value, required this.onChanged});

  @override
  State<_SettingToggle> createState() => _SettingToggleState();
}

class _SettingToggleState extends State<_SettingToggle> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(widget.icon, color: AppColors.secondary, size: 22),
      title: Text(widget.title, style: AppTextStyles.bodyMedium),
      trailing: Switch(value: _value, onChanged: (v) { setState(() => _value = v); widget.onChanged(v); }),
    );
  }
}
