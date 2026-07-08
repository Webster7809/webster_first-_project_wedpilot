import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/vendor_api_service.dart' show resolveMediaUrl;
import '../../../core/state/resource.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vendor_own_provider.dart';
import '../../../widgets/wed_snack_bar.dart';

class VendorProfileManagementScreen extends ConsumerStatefulWidget {
  const VendorProfileManagementScreen({super.key});

  @override
  ConsumerState<VendorProfileManagementScreen> createState() =>
      _VendorProfileManagementScreenState();
}

class _VendorProfileManagementScreenState
    extends ConsumerState<VendorProfileManagementScreen> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _websiteCtrl;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(vendorOwnProvider).data?.profile;
    _descCtrl = TextEditingController(text: profile?.description ?? '');
    _phoneCtrl = TextEditingController(text: profile?.phone ?? '');
    _websiteCtrl = TextEditingController(text: profile?.website ?? '');
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownResource = ref.watch(vendorOwnProvider);
    if (ownResource.status == ResourceStatus.initial) {
      Future.microtask(
        () => ref.read(vendorOwnProvider.notifier).loadOwnVendorData(),
      );
    }
    final ownState = ownResource.data;
    final vendor = ownState?.profile ?? ref.watch(vendorProfileProvider);
    final businessName = vendor?.businessName ?? 'My Business';
    final category = vendor?.category ?? 'Venue';
    final location = vendor?.location ?? '';
    final logoUrl = vendor?.logoUrl;
    final isSaving = ownState?.isSaving ?? false;
    final notificationsEnabled = ownState?.notificationsEnabled ?? true;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // ── Dark green header ────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: AppColors.forestGreen,
            expandedHeight: 120,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () => context.push('/notifications'),
              ),
              IconButton(
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () => _confirmLogout(context, ref),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'YOUR ACCOUNT',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.amber,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Profile & settings',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 48),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Business identity card ───────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.forestGreen.withAlpha(12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showLogoOptions(
                          context,
                          ref,
                          hasLogo: logoUrl != null,
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: logoUrl != null
                                  ? Image.network(
                                      resolveMediaUrl(logoUrl),
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      color: AppColors.amber,
                                      child: const Icon(
                                        Icons.storefront_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.forestGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              businessName,
                              style: AppTextStyles.titleLarge.copyWith(
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$category · $location',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.successBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_user_outlined,
                                    size: 12,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verified vendor',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Business info section ───────────────────────────────
                _SectionHeader(
                  icon: Icons.edit_outlined,
                  label: 'Business info',
                ),
                const SizedBox(height: 12),
                _AccountField(
                  icon: Icons.storefront_outlined,
                  label: 'Business name',
                  value: businessName,
                  readOnly: true,
                ),
                const SizedBox(height: 10),
                _AccountTextArea(
                  icon: Icons.description_outlined,
                  label: 'Description',
                  controller: _descCtrl,
                ),
                const SizedBox(height: 10),
                _AccountField(
                  icon: Icons.phone_outlined,
                  label: 'Phone number',
                  controller: _phoneCtrl,
                  inputType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                _AccountField(
                  icon: Icons.language_outlined,
                  label: 'Website',
                  controller: _websiteCtrl,
                  inputType: TextInputType.url,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final error = await ref
                                .read(vendorOwnProvider.notifier)
                                .saveProfile(
                                  description: _descCtrl.text.trim().isEmpty
                                      ? null
                                      : _descCtrl.text.trim(),
                                  phone: _phoneCtrl.text.trim().isEmpty
                                      ? null
                                      : _phoneCtrl.text.trim(),
                                  website: _websiteCtrl.text.trim().isEmpty
                                      ? null
                                      : _websiteCtrl.text.trim(),
                                );
                            if (!context.mounted) return;
                            if (error != null) {
                              showWedSnackBar(
                                context,
                                error,
                                type: SnackType.error,
                              );
                            } else {
                              showWedSnackBar(
                                context,
                                'Profile updated successfully!',
                                type: SnackType.success,
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save changes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Account section ──────────────────────────────────────
                _SectionHeader(icon: Icons.tune_outlined, label: 'Account'),
                const SizedBox(height: 12),
                _SettingsGroup(
                  rows: [
                    _ToggleRow(
                      icon: Icons.notifications_outlined,
                      label: 'New inquiry notifications',
                      value: notificationsEnabled,
                      onChanged: (v) => ref
                          .read(vendorOwnProvider.notifier)
                          .updateNotifications(v),
                    ),
                    _MenuRow(
                      icon: Icons.lock_outline_rounded,
                      label: 'Change password',
                      onTap: () {},
                    ),
                    _MenuRow(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & support',
                      onTap: () => context.push('/help'),
                    ),
                    _MenuRow(
                      icon: Icons.settings_outlined,
                      label: 'App settings',
                      onTap: () => context.push('/settings'),
                    ),
                  ],
                ),

                // Sign out — kept visually and spatially separate from the
                // neutral settings above, since it's a destructive action
                // and shouldn't share a tap-target group with routine
                // navigation (matches the pattern in settings_screen.dart).
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context, ref),
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    label: const Text('Sign out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadLogo(BuildContext context, WidgetRef ref) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null || !context.mounted) return;
    final bytes = await file.readAsBytes();
    if (!context.mounted) return;
    final error = await ref
        .read(vendorOwnProvider.notifier)
        .uploadLogo(bytes, file.name);
    if (!context.mounted) return;
    if (error != null) showWedSnackBar(context, error, type: SnackType.error);
  }

  void _showLogoOptions(
    BuildContext context,
    WidgetRef ref, {
    required bool hasLogo,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Business logo', style: AppTextStyles.headlineSmall),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _LogoOptionTile(
                  icon: Icons.photo_library_outlined,
                  iconColor: AppColors.forestGreen,
                  label: 'Choose from gallery',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickAndUploadLogo(context, ref);
                  },
                ),
                if (hasLogo) ...[
                  const Divider(height: 1, thickness: 1),
                  _LogoOptionTile(
                    icon: Icons.delete_outline_rounded,
                    iconColor: AppColors.error,
                    label: 'Remove logo',
                    labelColor: AppColors.error,
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      final error = await ref
                          .read(vendorOwnProvider.notifier)
                          .removeLogo();
                      if (!context.mounted) return;
                      if (error != null) {
                        showWedSnackBar(context, error, type: SnackType.error);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
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
}

// ── Logo option tile (used in the business-logo bottom sheet) ─────────────────

class _LogoOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  const _LogoOptionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: labelColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.amber),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.forestGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Single-line account field ─────────────────────────────────────────────────

class _AccountField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final TextEditingController? controller;
  final bool readOnly;
  final TextInputType inputType;

  const _AccountField({
    required this.icon,
    required this.label,
    this.value,
    this.controller,
    this.readOnly = false,
    this.inputType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller ?? TextEditingController(text: value),
      readOnly: readOnly,
      keyboardType: inputType,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
        ),
        prefixIcon: Icon(icon, size: 18, color: AppColors.amber),
        filled: true,
        fillColor: readOnly ? AppColors.creamDark : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.forestGreen,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}

// ── Multi-line text area ──────────────────────────────────────────────────────

class _AccountTextArea extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;

  const _AccountTextArea({
    required this.icon,
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 44),
          child: Icon(icon, size: 18, color: AppColors.amber),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.forestGreen,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}

// ── Grouped settings list ───────────────────────────────────────────────────
//
// One bordered/rounded card holding a set of rows with thin dividers between
// them, instead of each row being its own separately-boxed button — mirrors
// the pattern already used in couple_profile_screen.dart's `_SettingsList`.

class _SettingsGroup extends StatelessWidget {
  final List<Widget> rows;
  const _SettingsGroup({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              const Divider(
                height: 1,
                indent: 52,
                endIndent: 0,
                color: AppColors.divider,
              ),
          ],
        ],
      ),
    );
  }
}

// ── Toggle preference row ─────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, size: 20, color: AppColors.amber),
        title: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.forestGreen,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }
}

// ── Menu row ──────────────────────────────────────────────────────────────────

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, size: 20, color: AppColors.amber),
        title: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          size: 18,
          color: AppColors.textHint,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
    );
  }
}
