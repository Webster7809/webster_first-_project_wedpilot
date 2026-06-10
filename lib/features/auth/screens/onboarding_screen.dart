import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/wed_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _current = 0;

  final _slides = [
    _OnboardingSlide(
      emoji: '💰',
      title: 'Smart Budget Planning',
      subtitle: 'AI-powered budget allocation across all your wedding categories. Know exactly where every dollar goes.',
      color: AppColors.primary,
    ),
    _OnboardingSlide(
      emoji: '🌟',
      title: 'Discover Perfect Vendors',
      subtitle: 'AI matches you with verified vendors that fit your style, budget, and wedding date perfectly.',
      color: AppColors.accent,
    ),
    _OnboardingSlide(
      emoji: '💌',
      title: 'Beautiful Invitations',
      subtitle: 'Design stunning digital invitations and track RSVPs in real time from your dashboard.',
      color: AppColors.tertiary.withValues(alpha: 102),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < _slides.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: Text('Skip', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _OnboardingPage(slide: _slides[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _current ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _current ? AppColors.secondary : AppColors.divider,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 24),
                  WedButton(
                    label: _current == _slides.length - 1 ? 'Get Started' : 'Next',
                    onPressed: _next,
                    icon: _current == _slides.length - 1 ? Icons.celebration : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ', style: AppTextStyles.bodySmall),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text('Sign in', style: AppTextStyles.labelMedium.copyWith(color: AppColors.secondary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  const _OnboardingSlide({required this.emoji, required this.title, required this.subtitle, required this.color});
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingSlide slide;
  const _OnboardingPage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: slide.color,
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(slide.emoji, style: const TextStyle(fontSize: 60))),
          ),
          const SizedBox(height: 40),
          Text(slide.title, style: AppTextStyles.displaySmall, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(slide.subtitle,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.6),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
