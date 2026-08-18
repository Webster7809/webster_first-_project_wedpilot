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
    // Reachable from the field's "done" key, the button, and "Send it again"
    // on the sent view — all three can land on a request already in flight.
    if (ref.read(authProvider).isLoading) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref
        .read(authProvider.notifier)
        .forgotPassword(_emailCtrl.text.trim());
    if (!mounted) return;
    final error = ref.read(authProvider).error;
    if (error != null) {
      showWedSnackBar(context, error, type: SnackType.error);
      return;
    }
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));

    return AuthShell(
      // The same photograph as the login screen: this flow starts there and
      // returns there, so the image carries continuity rather than reading as
      // a different product.
      imageUrl: VendorCategoryImages.authHero(width: 1600)[0],
      eyebrow: _sent ? 'CHECK YOUR INBOX' : 'ACCOUNT RECOVERY',
      headline: _sent ? 'The link is on its way' : "Let's get you back in",
      supportLine: _sent
          ? 'The link expires after an hour, so open it while it is fresh.'
          : 'One email and you can set a new password. Your plans are '
              'untouched.',
      crossLinkPrompt: 'Remembered it?',
      crossLinkAction: 'Log in',
      crossLinkRoute: AppRoutes.login,
      onBack: () => context.canPop()
          ? context.pop()
          : context.go(AppRoutes.login),
      formBuilder: (context, _) => _sent
          ? _sentView(isLoading: isLoading)
          : _form(isLoading: isLoading),
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
            'Reset your password',
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.forestGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Enter the email on your account and we'll send a link to choose "
            'a new password.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          WedTextField(
            label: 'Email address',
            hint: 'you@email.com',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outlined,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your email';
              if (!v.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 26),

          WedButton(
            label: 'Send reset link',
            onPressed: _submit,
            variant: WedButtonVariant.primaryDark,
            isLoading: isLoading,
            borderRadius: 28,
          ),
        ],
      ),
    );
  }

  Widget _sentView({required bool isLoading}) {
    return AuthStatus(
      icon: Icons.mark_email_read_outlined,
      tone: AuthStatusTone.success,
      title: 'Check your email',
      message: 'We sent a reset link to ${_emailCtrl.text.trim()}. '
          "If it isn't in your inbox, look in spam.",
      actions: [
        WedButton(
          label: 'Back to log in',
          onPressed: () => context.go(AppRoutes.login),
          variant: WedButtonVariant.primaryDark,
          borderRadius: 28,
        ),
        WedButton(
          label: 'Send it again',
          onPressed: _submit,
          variant: WedButtonVariant.ghost,
          isLoading: isLoading,
          borderRadius: 28,
        ),
      ],
    );
  }
}
