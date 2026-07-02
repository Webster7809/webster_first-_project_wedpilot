import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/vendor_profile.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_snack_bar.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendor = ref.watch(vendorProfileProvider);
    final currentTier = vendor?.tier ?? VendorTier.free;
    final tierName = _tierDisplayName(currentTier);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        title: Text('Subscription',
            style: AppTextStyles.headlineMedium.copyWith(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Current plan banner ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.forestGreen.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.forestGreen.withAlpha(60)),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_outlined,
                    size: 28, color: AppColors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Plan: $tierName',
                          style: AppTextStyles.headlineSmall),
                      Text('Manage your plan below',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Available Plans', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),

          // ── Free ─────────────────────────────────────────────────────────
          _PlanCard(
            name: 'Free',
            price: 'ZMW 0',
            period: '/month',
            features: const [
              'Limited profile visibility',
              '5 portfolio images',
              'Basic lead inbox',
              'Standard support',
            ],
            isCurrent: currentTier == VendorTier.free,
            isPremium: false,
            onSelect: () => showWedSnackBar(context,
                'Upgrade to Free — payment integration coming soon',
                type: SnackType.info),
          ),
          const SizedBox(height: 12),

          // ── Pro ───────────────────────────────────────────────────────────
          _PlanCard(
            name: 'Pro',
            price: 'ZMW 490',
            period: '/month',
            features: const [
              'Full profile visibility',
              '50 images + 5 videos',
              'AI match algorithm',
              'Analytics dashboard',
              'Priority support',
            ],
            isCurrent: currentTier == VendorTier.pro,
            isPremium: false,
            onSelect: () => showWedSnackBar(context,
                'Upgrade to Pro — payment integration coming soon',
                type: SnackType.info),
          ),
          const SizedBox(height: 12),

          // ── Premium ───────────────────────────────────────────────────────
          _PlanCard(
            name: 'Premium',
            price: 'ZMW 990',
            period: '/month',
            features: const [
              'Priority placement in search',
              'Unlimited portfolio',
              'Featured badge',
              'Advanced analytics',
              'Dedicated account manager',
            ],
            isCurrent: currentTier == VendorTier.premium,
            isPremium: true,
            onSelect: () => showWedSnackBar(context,
                'Upgrade to Premium — payment integration coming soon',
                type: SnackType.info),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => showWedSnackBar(
                context, 'Billing history coming soon',
                type: SnackType.info),
            child: Text('View billing history',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.amber)),
          ),
        ],
      ),
    );
  }

  String _tierDisplayName(VendorTier tier) => switch (tier) {
        VendorTier.free => 'Free',
        VendorTier.pro => 'Pro',
        VendorTier.premium => 'Premium',
      };
}

class _PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final String period;
  final List<String> features;
  final bool isCurrent;
  final bool isPremium;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.name,
    required this.price,
    required this.period,
    required this.features,
    required this.isCurrent,
    required this.isPremium,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? AppColors.forestGreen
              : (isPremium ? AppColors.goldPremium : AppColors.divider),
          width: isCurrent || isPremium ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (isPremium)
                    const Icon(Icons.star_rounded,
                        size: 18, color: AppColors.amber),
                  if (isPremium) const SizedBox(width: 4),
                  Text(name, style: AppTextStyles.headlineSmall),
                  if (isCurrent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.forestGreen.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Current',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.forestGreen,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                        text: price,
                        style: AppTextStyles.displaySmall
                            .copyWith(color: AppColors.forestGreen)),
                    TextSpan(
                        text: period,
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text(f, style: AppTextStyles.bodySmall),
                  ],
                ),
              )),
          if (!isCurrent) ...[
            const SizedBox(height: 12),
            WedButton(
              label: 'Upgrade to $name',
              onPressed: onSelect,
              height: 44,
              variant: isPremium
                  ? WedButtonVariant.primary
                  : WedButtonVariant.secondary,
            ),
          ],
        ],
      ),
    );
  }
}
