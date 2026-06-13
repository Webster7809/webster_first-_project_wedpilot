import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/wed_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _HeroSection()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Everything you need', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    'The all-in-one platform for modern weddings',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  _FeatureCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'AI Budget Planning',
                    description:
                        'Smart allocation across all wedding categories. Track every dollar with confidence.',
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: 10),
                  _FeatureCard(
                    icon: Icons.storefront_rounded,
                    title: 'Discover Vendors',
                    description:
                        'Browse verified photographers, caterers, florists and more — matched to your style.',
                    color: AppColors.info,
                  ),
                  const SizedBox(height: 10),
                  _FeatureCard(
                    icon: Icons.mail_rounded,
                    title: 'Digital Invitations',
                    description:
                        'Design stunning invitations and track RSVPs in real time from your dashboard.',
                    color: AppColors.tertiary,
                  ),
                  const SizedBox(height: 10),
                  _FeatureCard(
                    icon: Icons.checklist_rounded,
                    title: 'Planning Checklist',
                    description:
                        'Stay on track with a personalised timeline from 12 months out to your big day.',
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: 24),
                  _StatsStrip(),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      WedButton(
                        label: "Get Started — It's Free",
                        onPressed: () => context.push('/register'),
                        icon: Icons.celebration_rounded,
                      ),
                      const SizedBox(height: 12),
                      WedButton(
                        label: 'Sign In to Your Account',
                        onPressed: () => context.go('/login'),
                        variant: WedButtonVariant.secondary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF880E4F), Color(0xFFAD1457), Color(0xFFC2185B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Decorative background circles
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 100,
            right: 40,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(12),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Sign In button — top-right, floating
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 20),
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: Colors.white.withAlpha(25),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    'Sign In',
                    style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),

          // Centered main content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),

                  // Centered logo mark
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('💍', style: TextStyle(fontSize: 36)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // App name
                  Text(
                    'Wedpilot',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: Colors.white,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Slogan
                  Text(
                    'Plan your perfect wedding,\nevery step of the way.',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: Colors.white.withAlpha(215),
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Feature badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: const [
                      _HeroBadge(label: '✨ AI-Powered'),
                      _HeroBadge(label: '🆓 Free to Start'),
                      _HeroBadge(label: '📱 All-in-One'),
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

class _HeroBadge extends StatelessWidget {
  final String label;
  const _HeroBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(60)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.textHint),
        ],
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.secondary.withAlpha(12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withAlpha(35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const _StatItem(value: '10K+', label: 'Happy Couples'),
          Container(width: 1, height: 32, color: AppColors.divider),
          const _StatItem(value: '2K+', label: 'Verified Vendors'),
          Container(width: 1, height: 32, color: AppColors.divider),
          const _StatItem(value: '4.9★', label: 'App Rating'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headlineMedium.copyWith(color: AppColors.secondary),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
