import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/wed_button.dart';

class EmailVerifyScreen extends StatefulWidget {
  const EmailVerifyScreen({super.key});

  @override
  State<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends State<EmailVerifyScreen> {
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            const SizedBox(height: 32),
            WedButton(
              label: _canResend ? 'Resend Email' : 'Resend in ${_countdown}s',
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
