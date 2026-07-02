import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';

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
                      _SettingItem(
                        icon: Icons.logout_rounded,
                        label: 'Sign Out',
                        isDestructive: true,
                        onTap: () async {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) context.go('/login');
                        },
                      ),
                    ],
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

// ── Hero header ───────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  final String coupleName;
  final dynamic profile;
  const _ProfileHero({required this.coupleName, this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.forestGreen, AppColors.coupleMagenta, AppColors.forestGreen],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withAlpha(128), width: 2),
              ),
              child: const Center(
                child: Text('💍', style: TextStyle(fontSize: 32)),
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
                _formatDate(profile.weddingDate as DateTime),
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
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
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
              const Divider(height: 1, indent: 52, endIndent: 0, color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;
  const _SettingItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.textSecondary;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 22, color: color),
      title: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
          fontWeight: isDestructive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isDestructive
          ? null
          : const Icon(Icons.chevron_right, size: 20, color: AppColors.textHint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
