import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/wed_card.dart';

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendor = ref.watch(vendorProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.secondary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.secondary,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      vendor?.businessName ?? 'My Business',
                      style: AppTextStyles.displaySmall.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vendor?.category ?? '',
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => context.push('/notifications'),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // KPI stats row
                Row(
                  children: [
                    _KpiCard(value: '24', label: 'Profile Views', icon: Icons.visibility_outlined, color: AppColors.info),
                    const SizedBox(width: 12),
                    _KpiCard(value: '5', label: 'New Leads', icon: Icons.mail_outline, color: AppColors.warning),
                    const SizedBox(width: 12),
                    _KpiCard(value: '87%', label: 'Score', icon: Icons.star_outline, color: AppColors.goldPremium),
                  ],
                ),
                const SizedBox(height: 20),

                // Profile completion
                WedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Profile Completion', style: AppTextStyles.headlineSmall),
                          Text('75%', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.secondary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: 0.75,
                        backgroundColor: AppColors.divider,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _CompletionChip(label: 'Bio ✓', done: true),
                          _CompletionChip(label: 'Photos', done: false),
                          _CompletionChip(label: 'Services ✓', done: true),
                          _CompletionChip(label: 'Location ✓', done: true),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quick nav cards
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _NavCard(emoji: '📥', title: 'Lead Inbox', subtitle: '5 new leads', color: AppColors.warning.withValues(alpha: 26), onTap: () => context.push('/vendor/leads')),
                    _NavCard(emoji: '💬', title: 'Messages', subtitle: '2 unread', color: AppColors.info.withValues(alpha: 26), onTap: () => context.push('/vendor/messages')),
                    _NavCard(emoji: '📅', title: 'Availability', subtitle: 'Update calendar', color: AppColors.tertiary.withValues(alpha: 51), onTap: () => context.push('/vendor/availability')),
                    _NavCard(emoji: '📊', title: 'Analytics', subtitle: 'View insights', color: AppColors.primary.withValues(alpha: 77), onTap: () => context.push('/vendor/analytics')),
                  ],
                ),
                const SizedBox(height: 16),

                // Subscription banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.goldPremium, AppColors.roseGoldPremium],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Upgrade to Premium', style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
                            Text('Priority placement + unlimited portfolio',
                                style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/vendor/subscription'),
                        child: const Text('Upgrade', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _KpiCard({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 4)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.headlineSmall.copyWith(color: color)),
            Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _CompletionChip extends StatelessWidget {
  final String label;
  final bool done;
  const _CompletionChip({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: AppTextStyles.caption.copyWith(
        color: done ? AppColors.success : AppColors.textSecondary,
      )),
      backgroundColor: done ? AppColors.success.withValues(alpha: 26) : AppColors.divider.withValues(alpha: 128),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _NavCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _NavCard({required this.emoji, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium),
                Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
