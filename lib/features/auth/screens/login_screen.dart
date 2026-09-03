import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/vendor_category_images.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/auth_shell.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_snack_bar.dart';
import '../../../widgets/wed_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // The password field submits on "done" as well as the button, so this can
    // be entered twice in a row.
    if (ref.read(authProvider).isLoading) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref
        .read(authProvider.notifier)
        .login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    final state = ref.read(authProvider);
    if (state.error != null) {
      showWedSnackBar(context, state.error!, type: SnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));

    return AuthShell(
      imageUrl: VendorCategoryImages.authHero(width: 1600)[0],
      eyebrow: 'WELCOME BACK',
      headline: 'Continue planning your perfect day',
      supportLine:
          'Your checklist, budget and vendor conversations are exactly where '
          'you left them.',
      crossLinkPrompt: 'New to WedPilot?',
      crossLinkAction: 'Create an account',
      crossLinkRoute: '/register',
      // Two fields and a password — nothing here pairs onto one line, so the
      // wide-form flag is unused.
      formBuilder: (context, _) => _form(isLoading: isLoading),
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
            'Sign in to your account',
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.forestGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pick up exactly where you left off.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          WedTextField(
            label: 'Email address',
            hint: 'you@email.com',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outlined,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (!v.contains('@')) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 18),

          WedTextField(
            label: 'Password',
            hint: '••••••••',
            controller: _passCtrl,
            isPassword: true,
            prefixIcon: Icons.lock_outlined,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _login(),
            // Six, not the eight the register screen asks for: accounts
            // created before that rule tightened still have shorter passwords,
            // and rejecting them here would lock those couples out.
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v.length < 6) return 'Min 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 6),

          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.r8),
                onTap: () => context.push('/forgot-password'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Text(
                    'Forgot password?',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          WedButton(
            label: 'Sign In',
            onPressed: _login,
            variant: WedButtonVariant.primaryDark,
            isLoading: isLoading,
            borderRadius: 28,
          ),
        ],
      ),
    );
  }
}
