import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/api_error.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/change_password_dialog.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_snack_bar.dart';
import '../../../widgets/wed_text_field.dart';

/// Shown for a Settings entry with no real functionality behind it yet
/// (partner access, data export, in-app rating) — matches the wording already
/// used elsewhere in the app (vendor_analytics_screen.dart,
/// subscription_screen.dart) rather than leaving the tap silently do nothing.
void _showComingSoon(BuildContext context, String feature) {
  showWedSnackBar(context, '$feature is coming soon.', type: SnackType.info);
}

/// Updates the local toggle instantly (offline-first, matches every other
/// setting here), then syncs it to the backend so it actually gates the
/// notification emails sent from there — see AuthService.updateNotificationPreferences.
/// Reverts the local toggle and surfaces an error if the sync fails, rather
/// than leaving the UI silently out of sync with what the server will honor.
Future<void> _setEmailNotifications(
  BuildContext context,
  WidgetRef ref,
  SettingsNotifier notifier,
  bool value,
) async {
  notifier.setEmailNotifications(value);
  final token = ref.read(authProvider.notifier).accessToken;
  if (token == null) return;
  try {
    await AuthService.instance.updateNotificationPreferences(
      accessToken: token,
      emailNotifications: value,
    );
  } on AuthApiException catch (e) {
    notifier.setEmailNotifications(!value);
    if (context.mounted) showWedSnackBar(context, e.message, type: SnackType.error);
  } catch (e) {
    notifier.setEmailNotifications(!value);
    if (context.mounted) showWedSnackBar(context, describeError(e), type: SnackType.error);
  }
}

/// Permanently deactivates the signed-in account — requires the current
/// password for the same reason `_showChangePasswordDialog` does (a live
/// session alone shouldn't be enough for something this irreversible). On
/// success, scrubs the local session the same way the Sign Out button below
/// does and returns to the login screen.
Future<void> _showDeleteAccountDialog(BuildContext context, WidgetRef ref) async {
  final formKey = GlobalKey<FormState>();
  final passwordCtrl = TextEditingController();
  bool submitting = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: const Text('Delete Account'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This permanently deactivates your account and removes your '
                'access — it can\'t be undone. Enter your password to '
                'confirm.',
                style: AppTextStyles.bodySmall.copyWith(height: 1.4),
              ),
              const SizedBox(height: 16),
              WedTextField(
                label: 'Password',
                controller: passwordCtrl,
                isPassword: true,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter your password' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: submitting ? null : () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          WedButton(
            label: 'Delete Account',
            variant: WedButtonVariant.danger,
            isLoading: submitting,
            shrinkWrap: true,
            height: 40,
            onPressed: submitting
                ? null
                : () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    setState(() => submitting = true);
                    final token = ref.read(authProvider.notifier).accessToken;
                    if (token == null) return;
                    try {
                      await AuthService.instance.deleteAccount(
                        accessToken: token,
                        currentPassword: passwordCtrl.text,
                      );
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                      ref.read(budgetProvider.notifier).clearBudget();
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        showWedSnackBar(context, 'Account deleted.', type: SnackType.success);
                        context.go('/login');
                      }
                    } on AuthApiException catch (e) {
                      setState(() => submitting = false);
                      if (dialogContext.mounted) {
                        showWedSnackBar(dialogContext, e.message, type: SnackType.error);
                      }
                    } catch (e) {
                      setState(() => submitting = false);
                      if (dialogContext.mounted) {
                        showWedSnackBar(dialogContext, describeError(e), type: SnackType.error);
                      }
                    }
                  },
          ),
        ],
      ),
    ),
  );
  passwordCtrl.dispose();
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
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
              onChanged: (value) => _setEmailNotifications(context, ref, notifier, value),
            ),
          ]),

          // ── Account ───────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.manage_accounts_outlined,
            title: 'Account',
          ),
          _SectionCard(children: [
            _NavTile(
              icon: Icons.person_outlined,
              title: 'Edit Profile',
              // Couple and vendor each have their own real profile editor —
              // route to whichever one applies rather than a generic no-op.
              // go(), not push(): both targets are tabs inside a
              // StatefulShellRoute, not standalone routes — pushing into a
              // shell branch from outside the shell renders blank.
              onTap: () => context.go(
                user?.role == UserRole.vendor ? '/vendor/account' : '/couple/profile',
              ),
            ),
            const Divider(height: 1, indent: 52),
            _NavTile(
              icon: Icons.email_outlined,
              title: 'Email Address',
              subtitle: user?.email ?? '—',
              // Display-only: there is no change-email flow yet, and a
              // tappable row that goes nowhere is worse than a plain one.
              onTap: null,
            ),
            const Divider(height: 1, indent: 52),
            _NavTile(
              icon: Icons.lock_outlined,
              title: 'Change Password',
              onTap: () => showChangePasswordDialog(context, ref),
            ),
            const Divider(height: 1, indent: 52),
            _NavTile(
              icon: Icons.people_outlined,
              title: 'Partner Access',
              onTap: () => _showComingSoon(context, 'Partner Access'),
            ),
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
              onTap: () => _showComingSoon(context, 'Data export'),
            ),
            const Divider(height: 1, indent: 52),
            _NavTile(
              icon: Icons.cookie_outlined,
              title: 'Cookie Preferences',
              onTap: () => context.push(AppRoutes.cookiePreferences),
            ),
            const Divider(height: 1, indent: 52),
            _NavTile(
              icon: Icons.policy_outlined,
              title: 'Privacy Policy',
              onTap: () => context.push(AppRoutes.privacyPolicy),
            ),
            const Divider(height: 1, indent: 52),
            _NavTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: () => context.push(AppRoutes.termsOfService),
            ),
          ]),

          // ── Support ───────────────────────────────────────────────
          _SectionHeader(
            icon: Icons.help_outlined,
            title: 'Support',
          ),
          _SectionCard(children: [
            _NavTile(
              icon: Icons.help_outlined,
              title: 'Help & FAQ',
              onTap: () => context.push('/help'),
            ),
            const Divider(height: 1, indent: 52),
            _NavTile(
              icon: Icons.star_outlined,
              title: 'Rate the App',
              // No store listing exists yet (the app isn't published), so
              // there is nowhere real for this to link to.
              onTap: () => _showComingSoon(context, 'App Store rating'),
            ),
            const Divider(height: 1, indent: 52),
            _NavTile(
              icon: Icons.info_outlined,
              title: 'App Version',
              subtitle: '1.0.0 (build 1)',
              onTap: null,
            ),
          ]),

          const SizedBox(height: 20),

          // Sign out — colorScheme.error, not AppColors.error: the raw token is
          // tuned for cream (it only reaches 2.99:1 on the dark scaffold),
          // while the dark theme already maps this slot to the lighter
          // AppColors.darkError.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Builder(builder: (context) {
              final error = Theme.of(context).colorScheme.error;
              return OutlinedButton.icon(
                onPressed: () async {
                  ref.read(budgetProvider.notifier).clearBudget();
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                icon: Icon(Icons.logout, color: error),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: error,
                  side: BorderSide(color: error),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => _showDeleteAccountDialog(context, ref),
              child: Text(
                'Delete Account',
                style: AppTextStyles.bodySmall
                    .copyWith(color: Theme.of(context).colorScheme.error),
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
          Icon(icon, size: 16, color: AppColors.goldDeep),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: AppTextStyles.labelMedium.copyWith(
              // Theme-aware, not AppColors.primary: forest green on the dark
              // scaffold is all but invisible (both are near-black).
              color: Theme.of(context).colorScheme.onSurface,
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
              const Icon(Icons.light_mode_outlined, size: 22, color: AppColors.goldDeep),
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
              const Icon(Icons.format_size, size: 22, color: AppColors.goldDeep),
              const SizedBox(width: 12),
              Text('Text Size', style: AppTextStyles.bodyMedium),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Preview — This is how text looks at the selected size.',
            style: TextStyle(
              fontSize: 13 * current.scale,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                // textOnSecondary on the gold fill (white on
                                // gold is 2.42:1), theme-aware when unselected
                                // so it stays readable on the dark card.
                                color: isSelected
                                    ? AppColors.textOnSecondary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              opt.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.textOnSecondary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
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
      leading: Icon(widget.icon, color: AppColors.goldDeep, size: 22),
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
      leading: Icon(icon, color: AppColors.goldDeep, size: 22),
      title: Text(title, style: AppTextStyles.bodyMedium),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTextStyles.caption)
          : null,
      trailing: onTap != null
          ? Icon(Icons.arrow_forward_ios,
              size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
