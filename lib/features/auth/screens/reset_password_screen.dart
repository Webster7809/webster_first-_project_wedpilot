import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/vendor_category_images.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/auth_shell.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_snack_bar.dart';
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

  bool get _tokenMissing => widget.token == null || widget.token!.isEmpty;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = widget.token;
    if (token == null || token.isEmpty) return;
    // The confirm field submits on "done" as well as the button.
    if (ref.read(authProvider).isLoading) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref.read(authProvider.notifier).resetPassword(
          token: token,
          newPassword: _passCtrl.text,
        );
    if (!mounted) return;
    final error = ref.read(authProvider).error;
    if (error != null) {
      showWedSnackBar(context, error, type: SnackType.error);
      return;
    }
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));

    final (eyebrow, headline, support) = switch ((_tokenMissing, _done)) {
      (true, _) => (
          'LINK PROBLEM',
          "This link won't work",
          'Reset links are single-use and expire after an hour.',
        ),
      (_, true) => (
          'ALL SET',
          'Your password is updated',
          'Sign in with the new one and pick up where you left off.',
        ),
      _ => (
          'ALMOST THERE',
          'Choose a new password',
          'Make it one you have not used on WedPilot before.',
        ),
    };

    return AuthShell(
      // Matches the login screen's photograph — the whole flow ends there.
      imageUrl: VendorCategoryImages.authHero(width: 1600)[0],
      eyebrow: eyebrow,
      headline: headline,
      supportLine: support,
      crossLinkPrompt: 'Remembered it?',
      crossLinkAction: 'Log in',
      crossLinkRoute: AppRoutes.login,
      // Reached by a deep link from an email — there is nothing behind it.
      formBuilder: (context, _) {
        if (_tokenMissing) return _invalidLinkView();
        if (_done) return _doneView();
        return _form(isLoading: isLoading);
      },
    );
  }

  Widget _form({required bool isLoading}) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Set a new password',
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.forestGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'It has to be different from the password you used before.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          WedTextField(
            label: 'New password',
            // The rule lives in the hint rather than a helperText: helperText
            // is swapped out for the error slot the moment validation fails,
            // which moves every control below it by a line.
            hint: 'At least 8 characters',
            controller: _passCtrl,
            isPassword: true,
            prefixIcon: Icons.lock_outlined,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v.length < 8) return 'Min 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 18),

          WedTextField(
            label: 'Confirm password',
            hint: 'Type it once more',
            controller: _confirmCtrl,
            isPassword: true,
            prefixIcon: Icons.lock_outlined,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v != _passCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 26),

          WedButton(
            label: 'Save new password',
            onPressed: _submit,
            variant: WedButtonVariant.primaryDark,
            isLoading: isLoading,
            borderRadius: 28,
          ),
        ],
      ),
    );
  }

  Widget _doneView() {
    return AuthStatus(
      icon: Icons.check_circle_outlined,
      tone: AuthStatusTone.success,
      title: 'Password updated',
      message: 'Your password has been reset. You can log in with the new one '
          'now.',
      actions: [
        WedButton(
          label: 'Go to log in',
          onPressed: () => context.go(AppRoutes.login),
          variant: WedButtonVariant.primaryDark,
          borderRadius: 28,
        ),
      ],
    );
  }

  Widget _invalidLinkView() {
    return AuthStatus(
      icon: Icons.link_off_outlined,
      tone: AuthStatusTone.error,
      title: 'Invalid reset link',
      message: 'This link is missing or malformed — it may have already been '
          'used. Request a fresh one to continue.',
      actions: [
        WedButton(
          label: 'Request a new link',
          onPressed: () => context.go(AppRoutes.forgotPassword),
          variant: WedButtonVariant.primaryDark,
          borderRadius: 28,
        ),
      ],
    );
  }
}
