import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/budget.dart';
import '../../../models/couple_profile.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/vendor_provider.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _didInitialize = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeBudget();
      }
    });
  }

  Future<void> _initializeBudget() async {
    if (_didInitialize) return;
    _didInitialize = true;

    final budgetState = ref.read(budgetProvider);
    final couple = ref.read(coupleProfileProvider);

    if (!budgetState.hasBudget && couple?.hasBudget == true) {
      await ref.read(budgetProvider.notifier).initializeBudgetForProfile(couple);
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetProvider);
    final user = ref.watch(currentUserProvider);
    final couple = ref.watch(coupleProfileProvider);
    final recommendations = ref.watch(recommendedVendorsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello ${user?.name?.split(' ').first ?? 'Webster'} 👋', style: AppTextStyles.displayMedium),
              const SizedBox(height: 8),
              Text('Your Wedding Plan', style: AppTextStyles.titleLarge.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              if (budgetState.isLoading)
                _buildLoadingCard()
              else if (budgetState.hasError)
                _buildErrorCard(budgetState.errorMessage ?? 'Something went wrong.', context)
              else if (!budgetState.hasBudget)
                _buildEmptyBudgetCard(context)
              else
                _buildBudgetSummary(budgetState.budget!, isWide),
              const SizedBox(height: 20),
              _buildQuickActions(isWide, context),
              const SizedBox(height: 20),
              _buildRecommendationsSection(recommendations, context),
              const SizedBox(height: 20),
              _buildUpcomingWedding(couple),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return WedCard(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Preparing your wedding overview...', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message, BuildContext context) {
    return WedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget Unavailable', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 10),
          Text(message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
          const SizedBox(height: 16),
          WedButton(
            label: 'Retry',
            onPressed: () => ref.read(budgetProvider.notifier).loadMockBudget(50000, 'USD'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBudgetCard(BuildContext context) {
    return WedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.secondary, size: 28),
              const SizedBox(width: 10),
              Text('Create your first wedding budget', style: AppTextStyles.headlineSmall),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Start with a tailored budget plan for your ceremony, vendors, and guest experience.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: WedButton(
                  label: 'Create Budget',
                  onPressed: () => context.push('/couple/budget/create'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/couple/vendors/recommendations'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('See Vendors'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSummary(Budget budget, bool isWide) {
    final summaryCards = [
      _buildStatCard('Budget', '${budget.currency} ${budget.totalAmount.toStringAsFixed(0)}', AppColors.secondary),
      _buildStatCard('Spent', '${budget.currency} ${budget.totalSpent.toStringAsFixed(0)}', AppColors.budgetRed),
      _buildStatCard('Remaining', '${budget.currency} ${budget.remainingBudget.toStringAsFixed(0)}', AppColors.budgetGreen),
    ];

    return Column(
      children: [
        _buildBudgetHeader(budget),
        const SizedBox(height: 18),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: summaryCards,
        ),
        const SizedBox(height: 18),
        _buildProgressCard(budget),
      ],
    );
  }

  Widget _buildBudgetHeader(Budget budget) {
    return WedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Wedding Budget Summary', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text('${budget.currency} ${budget.totalAmount.toStringAsFixed(0)}', style: AppTextStyles.displaySmall.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text('A beautiful budget overview for your most important planning milestone.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color accentColor) {
    return SizedBox(
      width: 280,
      child: WedCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.headlineMedium.copyWith(color: accentColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(Budget budget) {
    return WedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget Utilization', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: (budget.spendingPercentage / 100).clamp(0.0, 1.0),
              color: AppColors.secondary,
              backgroundColor: AppColors.divider,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Used ${budget.spendingPercentage.toStringAsFixed(0)}%', style: AppTextStyles.bodyMedium),
              Text('${budget.currency} ${budget.remainingBudget.toStringAsFixed(0)} left', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.budgetGreen)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isWide, BuildContext context) {
    final actions = [
      _ActionCard(label: 'Create Budget', icon: Icons.pie_chart, onTap: () => context.push('/couple/budget/create')),
      _ActionCard(label: 'Find Vendors', icon: Icons.storefront_outlined, onTap: () => context.push('/couple/vendors/recommendations')),
      _ActionCard(label: 'Reports', icon: Icons.bar_chart, onTap: () => context.push('/couple/budget')),
      _ActionCard(label: 'Recommendations', icon: Icons.star, onTap: () => context.push('/couple/vendors/recommendations')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: actions.map((action) => SizedBox(width: isWide ? 220 : double.infinity, child: action)).toList(),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection(List<dynamic> recommendations, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recommended Vendors', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 12),
        if (recommendations.isEmpty)
          WedCard(child: Text('No recommendations available yet.', style: AppTextStyles.bodyMedium))
        else
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recommendations.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final vendor = recommendations[index];
                return SizedBox(
                  width: 260,
                  child: VendorCard(
                    vendor: vendor,
                    isWishlisted: ref.watch(wishlistProvider).contains(vendor.id),
                    rank: index + 1,
                    onTap: () => context.push('/couple/vendors/${vendor.id}'),
                    onWishlistToggle: () => ref.read(wishlistProvider.notifier).toggle(vendor.id),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push('/couple/vendors/recommendations'),
            child: const Text('View all recommendations'),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingWedding(CoupleProfile? couple) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upcoming Wedding', style: AppTextStyles.headlineSmall),
        const SizedBox(height: 12),
        WedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(couple?.location ?? 'Lusaka', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 4),
              Text(
                'Date: ${couple?.weddingDate != null ? '${couple!.weddingDate!.month}/${couple.weddingDate!.day}/${couple.weddingDate!.year}' : '20 Dec 2026'}',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text('Guests: ${couple?.guestCount ?? 150}', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InfoPill(label: couple?.hasWeddingDate == true ? '${couple!.daysUntilWedding} days to go' : '180 days left'),
                  _InfoPill(label: couple?.styleTags.isNotEmpty == true ? couple!.styleTags.first : 'Romantic'),
                  _InfoPill(label: couple?.currency ?? 'ZMW'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: WedCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.secondary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;

  const _InfoPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
    );
  }
}
