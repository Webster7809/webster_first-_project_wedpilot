import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/vendor_category_images.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/google_signin_button.dart';
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
    if (!_formKey.currentState!.validate()) return;
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
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.forestGreen,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isTablet = w >= 600;
            final isDesktop = w >= 900;
            final maxWidth = isDesktop
                ? 450.0
                : (isTablet ? 500.0 : double.infinity);

            final content = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeroSection(isDesktop: isDesktop),
                _FormCard(
                  formKey: _formKey,
                  emailCtrl: _emailCtrl,
                  passCtrl: _passCtrl,
                  onLogin: _login,
                  isLoading: authState.isLoading,
                ),
              ],
            );

            return SingleChildScrollView(
              child: Center(
                child: maxWidth.isFinite
                    ? ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: content,
                      )
                    : content,
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final bool isDesktop;
  const _HeroSection({this.isDesktop = false});

  @override
  Widget build(BuildContext context) {
    // ConstrainedBox gives a minHeight (the original fixed design height) as
    // a floor, not a ceiling — the content Column below is the Stack's only
    // non-positioned child, so at large accessibility text-scale settings the
    // Stack (and the decorative background/circles filling it) grow to match
    // instead of the text overflowing a hard-capped SizedBox.
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: isDesktop ? 220 : 280),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: VendorCategoryImages.authHero()[0],
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 300),
              placeholder: (_, _) => Container(color: AppColors.forestGreen),
              errorWidget: (_, _, _) =>
                  Container(color: AppColors.forestGreen),
            ),
          ),
          // Scrim so the eyebrow/heading/circles stay legible over the photo.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.forestGreen.withAlpha(210),
                    AppColors.forestGreen.withAlpha(165),
                  ],
                ),
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: _Circle(size: 180, color: Colors.white.withAlpha(10)),
          ),
          Positioned(
            top: 30,
            right: 60,
            child: _Circle(size: 80, color: AppColors.amber.withAlpha(30)),
          ),
          Positioned(
            bottom: 40,
            left: -20,
            child: _Circle(size: 120, color: Colors.white.withAlpha(8)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: AppColors.textOnSecondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'WedPilot',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'WELCOME BACK',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    // Gold, not forest: this eyebrow sits on the forest hero
                    // (4.99:1). Forest on forest is invisible.
                    color: AppColors.gold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Continue planning\nyour perfect day',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  const _Circle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ── Form card ─────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final VoidCallback onLogin;
  final bool isLoading;

  const _FormCard({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.onLogin,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sign in to your account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.forestGreen,
              ),
            ),
            const SizedBox(height: 24),

            WedTextField(
              label: 'Email address',
              hint: 'you@email.com',
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (!v.contains('@')) return 'Invalid email';
                return null;
              },
            ),
            const SizedBox(height: 20),
            WedTextField(
              label: 'Password',
              hint: '••••••••',
              controller: passCtrl,
              isPassword: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 6) return 'Min 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => context.push('/forgot-password'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            WedButton(
              label: 'Sign In',
              onPressed: onLogin,
              variant: WedButtonVariant.primaryDark,
              isLoading: isLoading,
              height: 52,
              borderRadius: 28,
            ),
            const SizedBox(height: 20),
            const OrDivider(),
            const SizedBox(height: 20),
            GoogleSignInButton(role: UserRole.couple, isLoading: isLoading),
            const SizedBox(height: 32),

            Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => context.go('/register'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        children: const [
                          TextSpan(text: 'New to WedPilot? '),
                          TextSpan(
                            text: 'Create an account',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
