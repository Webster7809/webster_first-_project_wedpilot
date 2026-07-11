import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/wed_snack_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: cs.primary),
            onPressed: null,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 4),

          // ── Appearance ────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.palette_outlined,
            title: 'Appearance',
          ),
          _SectionCard(children: [
            _ThemeTile(
              currentMode: settings.themeMode,
              onChanged: notifier.setThemeMode,
            ),
          ]),

          // ── Accessibility ─────────────────────────────────────────
          _SectionHeader(
            icon: Icons.accessibility_new_outlined,
            title: 'Accessibility',
          ),
          _SectionCard(children: [
            _FontSizeTile(
              current: settings.fontSize,
              onChanged: notifier.setFontSize,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _ToggleTile(
              icon: Icons.contrast,
              title: 'High Contrast',
              subtitle: 'Stronger colours for better readability',
              value: settings.highContrast,
              onChanged: notifier.setHighContrast,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _ToggleTile(
              icon: Icons.motion_photos_off_outlined,
              title: 'Reduce Motion',
              subtitle: 'Minimise animations throughout the app',
              value: settings.reducedMotion,
              onChanged: notifier.setReducedMotion,
            ),
          ]),

          // ── Notifications ─────────────────────────────────────────
          _SectionHeader(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
          ),
          _SectionCard(children: [
            _ToggleTile(
              icon: Icons.notifications_outlined,
              title: 'Push Notifications',
              subtitle: 'Real-time alerts on your device',
              value: settings.pushNotifications,
              onChanged: notifier.setPushNotifications,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _ToggleTile(
              icon: Icons.email_outlined,
              title: 'Email Notifications',
              subtitle: 'Updates delivered to your inbox',
              value: settings.emailNotifications,
              onChanged: notifier.setEmailNotifications,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _ToggleTile(
              icon: Icons.sms_outlined,
              title: 'SMS Notifications',
              subtitle: 'Important alerts via text message',
              value: settings.smsNotifications,
              onChanged: notifier.setSmsNotifications,
            ),
          ]),

          // ── Account ───────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.manage_accounts_outlined,
            title: 'Account',
          ),
          _SectionCard(children: [
            _NavTile(icon: Icons.person_outline, title: 'Edit Profile', onTap: () {}),
            const Divider(height: 1, indent: 52),
            _NavTile(
              icon: Icons.email_outlined,
              title: 'Email Address',
              subtitle: user?.email ?? '—',
              onTap: () {},
            ),
            const Divider(height: 1, indent: 52),
            _NavTile(icon: Icons.lock_outline, title: 'Change Password', onTap: () {}),
            const Divider(height: 1, indent: 52),
            _NavTile(icon: Icons.people_outline, title: 'Partner Access', onTap: () {}),
          ]),

          // ── Privacy & Data ────────────────────────────────────────
          _SectionHeader(
            icon: Icons.security_outlined,
            title: 'Privacy & Data',
          ),
          _SectionCard(children: [
            _NavTile(
              icon: Icons.download_outlined,
              title: 'Export My Data',
              onTap: () => showWedSnackBar(
                context,
                'Data export requested!',
                type: SnackType.success,
              ),
            ),
            const Divider(height: 1, indent: 52),
            _NavTile(icon: Icons.cookie_outlined, title: 'Cookie Preferences', onTap: () {}),
            const Divider(height: 1, indent: 52),
            _NavTile(icon: Icons.policy_outlined, title: 'Privacy Policy', onTap: () {}),
            const Divider(height: 1, indent: 52),
            _NavTile(icon: Icons.description_outlined, title: 'Terms of Service', onTap: () {}),
          ]),

          // ── Support ───────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.help_outline,
            title: 'Support',
          ),
          _SectionCard(children: [
            _NavTile(
              icon: Icons.help_outline,
              title: 'Help & FAQ',
              onTap: () => context.push('/help'),
            ),
            const Divider(height: 1, indent: 52),
            _NavTile(
              icon: Icons.star_outline,
              title: 'Rate the App',
              onTap: () {},
            ),
            const Divider(height: 1, indent: 52),
            _NavTile(
              icon: Icons.info_outline,
              title: 'App Version',
              subtitle: '1.0.0 (build 1)',
              onTap: null,
            ),
          ]),

          const SizedBox(height: 20),

          // Sign out
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                ref.read(budgetProvider.notifier).clearBudget();
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Delete Account',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.secondary),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.secondary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section card ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        elevation: theme.brightness == Brightness.dark ? 0 : 1,
        shadowColor: AppColors.cardShadow,
        child: Column(children: children),
      ),
    );
  }
}

// ── Theme selector ─────────────────────────────────────────────────────────

class _ThemeTile extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;
  const _ThemeTile({required this.currentMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.light_mode_outlined, size: 22, color: AppColors.secondary),
              const SizedBox(width: 12),
              Text('Theme', style: AppTextStyles.bodyMedium),
            ],
          ),
          const SizedBox(height: 14),
          // SegmentedButton doesn't shrink its own intrinsic width to fit
          // narrow screens (a known Flutter overflow case); wrapping it in
          // Expanded forces it to size within the available width instead.
          Row(
            children: [
              Expanded(
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(Icons.brightness_auto_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode_outlined, size: 16),
                    ),
                  ],
                  selected: {currentMode},
                  onSelectionChanged: (modes) => onChanged(modes.first),
                  style: ButtonStyle(
                    textStyle: WidgetStateProperty.all(
                      const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Font size selector ─────────────────────────────────────────────────────

class _FontSizeTile extends StatelessWidget {
  final FontSizeOption current;
  final ValueChanged<FontSizeOption> onChanged;
  const _FontSizeTile({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_size, size: 22, color: AppColors.secondary),
              const SizedBox(width: 12),
              Text('Text Size', style: AppTextStyles.bodyMedium),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Preview — This is how text looks at the selected size.',
            style: TextStyle(
              fontSize: 13 * current.scale,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: FontSizeOption.values.map((opt) {
              final isSelected = opt == current;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: opt != FontSizeOption.values.last ? 8 : 0,
                  ),
                  child: Material(
                    animationDuration: const Duration(milliseconds: 180),
                    color: isSelected ? AppColors.secondary : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AppColors.secondary : AppColors.divider,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onChanged(opt),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Aa',
                              style: TextStyle(
                                fontSize: 12 + (opt.index * 3.0),
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              opt.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Toggle tile ────────────────────────────────────────────────────────────

class _ToggleTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_ToggleTile> createState() => _ToggleTileState();
}

class _ToggleTileState extends State<_ToggleTile> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(_ToggleTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(widget.icon, color: AppColors.secondary, size: 22),
      title: Text(widget.title, style: AppTextStyles.bodyMedium),
      subtitle: Text(
        widget.subtitle,
        style: AppTextStyles.caption.copyWith(height: 1.3),
      ),
      trailing: Switch(
        value: _value,
        onChanged: (v) {
          setState(() => _value = v);
          widget.onChanged(v);
        },
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

// ── Navigation tile ────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.secondary, size: 22),
      title: Text(title, style: AppTextStyles.bodyMedium),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTextStyles.caption)
          : null,
      trailing: onTap != null
          ? const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary)
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
