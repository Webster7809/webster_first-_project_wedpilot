import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_text_field.dart';
import '../../../widgets/wed_snack_bar.dart';

const _googleSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
</svg>''';

const _appleSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path d="M12.152 6.896c-.948 0-2.415-1.078-3.96-1.04-2.04.027-3.91 1.183-4.961 3.014-2.117 3.675-.541 9.103 1.519 12.087 1.013 1.454 2.208 3.095 3.792 3.039 1.52-.065 2.09-.987 3.935-.987 1.831 0 2.35.987 3.96.948 1.637-.026 2.676-1.48 3.676-2.948 1.156-1.688 1.636-3.325 1.662-3.415-.039-.013-3.182-1.221-3.208-4.868-.026-3.053 2.495-4.51 2.612-4.588-1.43-2.106-3.662-2.34-4.428-2.392-1.975-.143-3.909 1.169-4.599 1.169zm3.378-3.066c.843-1.012 1.4-2.427 1.245-3.83-1.207.052-2.662.805-3.532 1.818-.777.9-1.454 2.397-1.273 3.654 1.338.104 2.715-.688 3.56-1.642z"/>
</svg>''';

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
    await ref.read(authProvider.notifier).login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    final state = ref.read(authProvider);
    if (state.error != null) {
      showWedSnackBar(context, state.error!, type: SnackType.error);
    } else {
      final user = state.user!;
      switch (user.role.name) {
        case 'couple': context.go('/couple/dashboard'); break;
        case 'vendor': context.go('/vendor/dashboard'); break;
        case 'admin': context.go('/admin/dashboard'); break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CustomPaint(
                            size: const Size(64, 64),
                            painter: _HeartEmblemPainter(),
                          ),
                          const SizedBox(height: 16),
                          Text('Welcome back', style: AppTextStyles.displaySmall),
                          const SizedBox(height: 4),
                          Text('Sign in to your Wedpilot account',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    WedTextField(
                      label: 'Email address',
                      hint: 'you@example.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter your email';
                        if (!v.contains('@')) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    WedTextField(
                      label: 'Password',
                      hint: '••••••••',
                      controller: _passCtrl,
                      isPassword: true,
                      prefixIcon: Icons.lock_outline,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter your password';
                        if (v.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: Text('Forgot password?',
                            style: AppTextStyles.labelMedium.copyWith(color: AppColors.secondary)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    WedButton(
                      label: 'Sign In',
                      onPressed: _login,
                      isLoading: authState.isLoading,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or continue with', style: AppTextStyles.caption),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _OAuthButton(
                            label: 'Google',
                            icon: SvgPicture.string(_googleSvg, width: 20, height: 20),
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OAuthButton(
                            label: 'Apple',
                            icon: SvgPicture.string(
                              _appleSvg,
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(Colors.black87, BlendMode.srcIn),
                            ),
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Don't have an account? ", style: AppTextStyles.bodySmall),
                          TextButton(
                            onPressed: () => context.push('/register'),
                            child: Text('Sign up', style: AppTextStyles.labelMedium.copyWith(color: AppColors.secondary)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Demo: use any email\n• vendor@test.com → Vendor dashboard\n• admin@test.com → Admin dashboard\n• anything else → Couple dashboard',
                        style: AppTextStyles.caption.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OAuthButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  const _OAuthButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.labelLarge),
        ],
      ),
    );
  }
}

class _HeartEmblemPainter extends CustomPainter {
  const _HeartEmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    canvas.drawCircle(
      Offset(cx, cy),
      w * 0.46,
      Paint()
        ..color = const Color(0x30F8BBD9)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      w * 0.46,
      Paint()
        ..color = const Color(0x60F06292)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final s = w * 0.24;
    final hc = Offset(cx, cy + s * 0.12);
    final heartPath = Path()
      ..moveTo(hc.dx, hc.dy + s * 0.74)
      ..cubicTo(hc.dx - s * 1.6, hc.dy, hc.dx - s * 1.6, hc.dy - s * 0.88,
          hc.dx, hc.dy - s * 0.14)
      ..cubicTo(hc.dx + s * 1.6, hc.dy - s * 0.88, hc.dx + s * 1.6, hc.dy,
          hc.dx, hc.dy + s * 0.74);
    canvas.drawPath(
      heartPath,
      Paint()
        ..color = const Color(0xFFF06292)
        ..style = PaintingStyle.fill,
    );

    final dotPaint = Paint()
      ..color = const Color(0xFFF06292).withAlpha(120)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      final angle = i * 2 * math.pi / 8;
      canvas.drawCircle(
        Offset(cx + w * 0.46 * math.cos(angle), cy + w * 0.46 * math.sin(angle)),
        2.0,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_HeartEmblemPainter old) => false;
}
