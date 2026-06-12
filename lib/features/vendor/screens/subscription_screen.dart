import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_snack_bar.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Subscription')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current plan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withAlpha(77)),
            ),
            child: Row(
              children: [
                const Text('📋', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current Plan: Pro', style: AppTextStyles.headlineSmall),
                      Text('Renews Dec 1, 2026 · \$49/month',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('Available Plans', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),

          _PlanCard(
            name: 'Free',
            price: '\$0',
            period: '/month',
            features: const ['Limited profile visibility', '5 portfolio images', 'Basic lead inbox', 'Standard support'],
            isCurrent: false,
            isPremium: false,
            onSelect: () {},
          ),
          const SizedBox(height: 12),
          _PlanCard(
            name: 'Pro',
            price: '\$49',
            period: '/month',
            features: const ['Full profile visibility', '50 images + 5 videos', 'AI match algorithm', 'Analytics dashboard', 'Priority support'],
            isCurrent: true,
            isPremium: false,
            onSelect: () {},
          ),
          const SizedBox(height: 12),
          _PlanCard(
            name: 'Premium',
            price: '\$99',
            period: '/month',
            features: const ['Priority placement in search', 'Unlimited portfolio', 'Featured badge', 'Advanced analytics', 'Dedicated account manager'],
            isCurrent: false,
            isPremium: true,
            onSelect: () => showWedSnackBar(context, 'Redirecting to Stripe...', type: SnackType.info),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {},
            child: Text('View billing history', style: AppTextStyles.labelMedium.copyWith(color: AppColors.secondary)),
          ),
        ],
      ),
    );
  }
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? AppColors.secondary : (isPremium ? AppColors.goldPremium : AppColors.divider),
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
                  Text(isPremium ? '⭐ ' : '', style: const TextStyle(fontSize: 18)),
                  Text(name, style: AppTextStyles.headlineSmall),
                  if (isCurrent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withAlpha(31),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Current',
                          style: AppTextStyles.caption.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: price, style: AppTextStyles.displaySmall.copyWith(color: AppColors.secondary)),
                    TextSpan(text: period, style: AppTextStyles.caption),
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
                    const Icon(Icons.check_circle, size: 16, color: AppColors.success),
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
              variant: isPremium ? WedButtonVariant.primary : WedButtonVariant.secondary,
            ),
          ],
        ],
      ),
    );
  }
}
