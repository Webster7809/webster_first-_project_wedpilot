import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authProvider.notifier)
        .forgotPassword(_emailCtrl.text.trim());
    if (!mounted) return;
    final error = ref.read(authProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isPhone = w < 600;
            final isDesktop = w >= 900;
            // Same responsive card width as the register screen, so this
            // screen's form reads consistently with it at every breakpoint.
            final maxWidth = isDesktop ? 650.0 : (!isPhone ? 550.0 : w * 0.9);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: _sent
                      ? _SentView(onBack: () => context.go('/login'))
                      : Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.forestGreen.withAlpha(26),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock_reset_rounded,
                                  size: 32,
                                  color: AppColors.forestGreen,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text('Forgot your password?',
                                  style: AppTextStyles.displaySmall),
                              const SizedBox(height: 8),
                              Text(
                                'Enter your email address and we\'ll send you a link to reset your password.',
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary, height: 1.5),
                              ),
                              const SizedBox(height: 32),
                              WedTextField(
                                label: 'Email address',
                                hint: 'you@example.com',
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.email_outlined,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!v.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              WedButton(
                                label: 'Send Reset Link',
                                onPressed: _submit,
                                isLoading: isLoading,
                                height: 40,
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: TextButton(
                                  onPressed: () => context.go('/login'),
                                  child: Text(
                                    'Back to Login',
                                    style: AppTextStyles.labelMedium
                                        .copyWith(color: AppColors.secondary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SentView extends StatelessWidget {
  final VoidCallback onBack;
  const _SentView({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: AppColors.success.withAlpha(26),
                shape: BoxShape.circle),
            child: const Icon(Icons.mark_email_read_outlined,
                size: 40, color: AppColors.success),
          ),
          const SizedBox(height: 24),
          Text('Check your email', style: AppTextStyles.displaySmall),
          const SizedBox(height: 12),
          Text(
            'We\'ve sent a password reset link. Check your inbox and follow the instructions.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          WedButton(label: 'Back to Login', onPressed: onBack),
        ],
      ),
    );
  }
}
