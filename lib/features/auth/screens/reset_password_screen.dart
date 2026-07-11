import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_text_field.dart';

/// Landing screen for the link emailed by ForgotPasswordScreen — reads the
/// reset [token] out of the URL's query string (see AppRoutes.resetPassword)
/// and lets the user set a new password against it.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? token;
  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _done = false;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = widget.token;
    if (token == null || token.isEmpty) return;
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).resetPassword(
          token: token,
          newPassword: _passCtrl.text,
        );
    if (!mounted) return;
    final error = ref.read(authProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final tokenMissing = widget.token == null || widget.token!.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isPhone = w < 600;
            final isDesktop = w >= 900;
            final maxWidth = isDesktop ? 650.0 : (!isPhone ? 550.0 : w * 0.9);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: tokenMissing
                      ? _InvalidLinkView(
                          onBack: () => context.go('/forgot-password'),
                        )
                      : _done
                          ? _DoneView(onBack: () => context.go('/login'))
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
                                      Icons.lock_outline_rounded,
                                      size: 32,
                                      color: AppColors.forestGreen,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text('Choose a new password',
                                      style: AppTextStyles.displaySmall),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Your new password must be different from your previous password.',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                        height: 1.5),
                                  ),
                                  const SizedBox(height: 32),
                                  WedTextField(
                                    label: 'New password',
                                    hint: 'Enter new password',
                                    controller: _passCtrl,
                                    isPassword: true,
                                    prefixIcon: Icons.lock_outline,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Required';
                                      if (v.length < 8) return 'Min 8 characters';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  WedTextField(
                                    label: 'Confirm password',
                                    hint: 'Re-enter new password',
                                    controller: _confirmCtrl,
                                    isPassword: true,
                                    prefixIcon: Icons.lock_outline,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Required';
                                      if (v != _passCtrl.text) return 'Passwords do not match';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  WedButton(
                                    label: 'Reset Password',
                                    onPressed: _submit,
                                    isLoading: isLoading,
                                    height: 40,
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

class _DoneView extends StatelessWidget {
  final VoidCallback onBack;
  const _DoneView({required this.onBack});

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
                color: AppColors.success.withAlpha(26), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline_rounded,
                size: 40, color: AppColors.success),
          ),
          const SizedBox(height: 24),
          Text('Password updated', style: AppTextStyles.displaySmall),
          const SizedBox(height: 12),
          Text(
            'Your password has been reset. You can now log in with your new password.',
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

class _InvalidLinkView extends StatelessWidget {
  final VoidCallback onBack;
  const _InvalidLinkView({required this.onBack});

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
                color: AppColors.error.withAlpha(26), shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded,
                size: 40, color: AppColors.error),
          ),
          const SizedBox(height: 24),
          Text('Invalid reset link', style: AppTextStyles.displaySmall),
          const SizedBox(height: 12),
          Text(
            'This password reset link is missing or malformed. Request a new one to continue.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          WedButton(label: 'Request New Link', onPressed: onBack),
        ],
      ),
    );
  }
}
