import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/wed_button.dart';

class EmailVerifyScreen extends ConsumerStatefulWidget {
  const EmailVerifyScreen({super.key});

  @override
  ConsumerState<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends ConsumerState<EmailVerifyScreen> {
  int _countdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() async {
    while (_countdown > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _countdown--);
    }
    if (mounted) setState(() => _canResend = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Verify Email')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Center(child: Text('📧', style: TextStyle(fontSize: 44))),
            ),
            const SizedBox(height: 24),
            Text('Verify your email', style: AppTextStyles.displaySmall),
            const SizedBox(height: 12),
            Text(
              'We\'ve sent a verification email. Click the link in the email to activate your account.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            WedButton(
              label: "I've Verified — Continue",
              width: 260,
              onPressed: () {
                final role = ref.read(authProvider).user?.role;
                if (role == UserRole.couple) {
                  context.go('/couple-planning');
                } else {
                  context.go('/vendor-onboarding');
                }
              },
            ),
            const SizedBox(height: 12),
            WedButton(
              label: _canResend ? 'Resend Email' : 'Resend in ${_countdown}s',
              width: 220,
              onPressed: _canResend ? () {
                setState(() { _countdown = 60; _canResend = false; });
                _startCountdown();
              } : null,
              variant: WedButtonVariant.secondary,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/login'),
              child: Text('Back to Login', style: AppTextStyles.labelMedium.copyWith(color: AppColors.secondary)),
            ),
          ],
        ),
      ),
    );
  }
}
