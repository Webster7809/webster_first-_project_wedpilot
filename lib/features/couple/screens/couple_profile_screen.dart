import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/couple_profile_service.dart';
import '../../../core/services/vendor_api_service.dart' show resolveMediaUrl;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/couple_profile.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/wed_snack_bar.dart';

class CoupleProfileScreen extends ConsumerWidget {
  const CoupleProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final profile = ref.watch(coupleProfileProvider);
    final name1 = auth.user?.name;
    final name2 = profile?.partnerName;
    final coupleName = name1 == null
        ? 'Your Wedding'
        : (name2 != null && name2.isNotEmpty ? '$name1 & $name2' : name1);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.forestGreen,
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
                onPressed: () => _confirmSignOut(context, ref),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHero(
                coupleName: coupleName,
                profile: profile,
              ),
            ),
            title: const Text(''),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Planning tools
                  Text('Planning Tools', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 14),
                  _ToolGrid(
                    items: [
                      _ToolItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Messages',
                        color: AppColors.info,
                        onTap: () => context.push('/couple/messages'),
                      ),
                      _ToolItem(
                        icon: Icons.checklist_rounded,
                        label: 'Checklist',
                        color: AppColors.tertiary,
                        onTap: () => context.push('/couple/checklist'),
                      ),
                      _ToolItem(
                        icon: Icons.favorite_outline_rounded,
                        label: 'Wishlist',
                        color: AppColors.secondary,
                        onTap: () => context.push('/couple/wishlist'),
                      ),
                      _ToolItem(
                        icon: Icons.rate_review_outlined,
                        label: 'Reviews',
                        color: AppColors.goldPremium,
                        onTap: () => context.push('/couple/reviews/new'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Account
                  Text('Account', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 14),
                  _SettingsList(
                    items: [
                      _SettingItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        onTap: () => context.push('/notifications'),
                      ),
                      _SettingItem(
                        icon: Icons.settings_outlined,
                        label: 'App Settings',
                        onTap: () => context.push('/settings'),
                      ),
                      _SettingItem(
                        icon: Icons.help_outline_rounded,
                        label: 'Help & FAQ',
                        onTap: () => context.push('/help'),
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
                      onPressed: () => _confirmSignOut(context, ref),
                      icon: const Icon(Icons.logout, color: AppColors.error),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _confirmSignOut(BuildContext context, WidgetRef ref) {
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
          onPressed: () async {
            Navigator.of(ctx).pop();
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Log Out'),
        ),
      ],
    ),
  );
}

// ── Hero header ───────────────────────────────────────────────────────────────

class _ProfileHero extends ConsumerWidget {
  final String coupleName;
  final CoupleProfile? profile;
  const _ProfileHero({required this.coupleName, this.profile});

  Future<void> _pickAndUploadPhoto(BuildContext context, WidgetRef ref) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final token = ref.read(authProvider.notifier).accessToken;
    if (!context.mounted || token == null) return;
    try {
      final saved = await CoupleProfileService.instance.uploadPhoto(
        token,
        bytes: bytes,
        filename: file.name,
      );
      ref.read(authProvider.notifier).setCoupleProfile(saved);
    } on CoupleProfileApiException catch (e) {
      if (context.mounted) {
        showWedSnackBar(context, e.message, type: SnackType.error);
      }
    }
  }

  Future<void> _removePhoto(BuildContext context, WidgetRef ref) async {
    final token = ref.read(authProvider.notifier).accessToken;
    if (token == null) return;
    try {
      final saved = await CoupleProfileService.instance.removePhoto(token);
      ref.read(authProvider.notifier).setCoupleProfile(saved);
    } on CoupleProfileApiException catch (e) {
      if (context.mounted) {
        showWedSnackBar(context, e.message, type: SnackType.error);
      }
    } catch (_) {
      if (context.mounted) {
        showWedSnackBar(
          context,
          'Could not reach the server. Please try again.',
          type: SnackType.error,
        );
      }
    }
  }

  void _showPhotoOptions(
    BuildContext context,
    WidgetRef ref, {
    required bool hasPhoto,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
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
                    Text(
                      'Profile photo',
                      style: AppTextStyles.headlineSmall,
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _PhotoOptionTile(
                  icon: Icons.photo_library_outlined,
                  iconColor: AppColors.forestGreen,
                  label: 'Choose from gallery',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickAndUploadPhoto(context, ref);
                  },
                ),
                if (hasPhoto) ...[
                  const Divider(height: 1, thickness: 1),
                  _PhotoOptionTile(
                    icon: Icons.delete_outline_rounded,
                    iconColor: AppColors.error,
                    label: 'Remove photo',
                    labelColor: AppColors.error,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _removePhoto(context, ref);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoUrl = profile?.photoUrl;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.forestGreen,
            AppColors.coupleMagenta,
            AppColors.forestGreen,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () =>
                  _showPhotoOptions(context, ref, hasPhoto: photoUrl != null),
              child: Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withAlpha(128),
                        width: 2,
                      ),
                    ),
                    child: photoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              resolveMediaUrl(photoUrl),
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Center(
                            child: Text('💍', style: TextStyle(fontSize: 32)),
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.forestGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              coupleName,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            if (profile?.weddingDate != null)
              Text(
                _formatDate(profile!.weddingDate!),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withAlpha(204),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }
}

// ── Photo option tile (used in the profile-photo bottom sheet) ────────────────

class _PhotoOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  const _PhotoOptionTile({
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

// ── Tool grid (2-column) ──────────────────────────────────────────────────────

class _ToolGrid extends StatelessWidget {
  final List<_ToolItem> items;
  const _ToolGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.0,
      children: items,
    );
  }
}

class _ToolItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ToolItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Text(label, style: AppTextStyles.labelLarge),
          ],
        ),
      ),
    );
  }
}

// ── Settings list ─────────────────────────────────────────────────────────────

class _SettingsList extends StatelessWidget {
  final List<_SettingItem> items;
  const _SettingsList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
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

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SettingItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, size: 22, color: AppColors.textSecondary),
        title: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          size: 20,
          color: AppColors.textHint,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
