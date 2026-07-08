import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _formKey = GlobalKey<FormState>();

  final _partner1Ctrl = TextEditingController();
  final _partner2Ctrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  UserRole get _role => _tab.index == 0 ? UserRole.couple : UserRole.vendor;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    _partner1Ctrl.dispose();
    _partner2Ctrl.dispose();
    _businessNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _role == UserRole.couple
        ? _partner1Ctrl.text.trim()
        : _businessNameCtrl.text.trim();
    await ref
        .read(authProvider.notifier)
        .register(
          name,
          _emailCtrl.text.trim(),
          _passCtrl.text,
          _role,
          partner2Name: _role == UserRole.couple
              ? _partner2Ctrl.text.trim()
              : null,
          phone: _phoneCtrl.text.trim(),
        );
    if (!mounted) return;
    final err = ref.read(authProvider).error;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    } else {
      context.go('/verify-email');
    }
  }

  String? _required(String? v) => (v == null || v.isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.forestGreen,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isPhone = w < 600;
            final isDesktop = w >= 900;

            // Responsive card max-width
            final cardMaxWidth = isDesktop
                ? 650.0
                : (!isPhone ? 550.0 : w * 0.9);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cardMaxWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Brand header ──────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.amber,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'WedPilot',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'GET STARTED',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.amber,
                                letterSpacing: 1.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Plan the wedding\nyou both deserve',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Form card ─────────────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppShadows.xl,
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Role tabs ──────────────────────────────────
                              Container(
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppColors.divider,
                                    ),
                                  ),
                                ),
                                child: TabBar(
                                  controller: _tab,
                                  isScrollable: false,
                                  dividerColor: Colors.transparent,
                                  indicator: const UnderlineTabIndicator(
                                    borderSide: BorderSide(
                                      color: AppColors.forestGreen,
                                      width: 2,
                                    ),
                                  ),
                                  labelColor: AppColors.forestGreen,
                                  unselectedLabelColor: AppColors.textHint,
                                  labelStyle: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  unselectedLabelStyle: GoogleFonts.inter(
                                    fontSize: 14,
                                  ),
                                  tabs: const [
                                    Tab(text: "I'm a couple"),
                                    Tab(text: "I'm a vendor"),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── Name field(s) ──────────────────────────────
                              if (_role == UserRole.couple) ...[
                                if (isPhone) ...[
                                  WedTextField(
                                    borderRadius: 16,
                                    fillColor: AppColors.inputFillAlt,
                                    hint: 'Partner 1',
                                    controller: _partner1Ctrl,
                                    validator: _required,
                                    prefixIcon: Icons.person_outline,
                                  ),
                                  const SizedBox(height: 20),
                                  WedTextField(
                                    borderRadius: 16,
                                    fillColor: AppColors.inputFillAlt,
                                    hint: 'Partner 2',
                                    controller: _partner2Ctrl,
                                    validator: _required,
                                    prefixIcon: Icons.person_outline,
                                  ),
                                ] else ...[
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: WedTextField(
                                          borderRadius: 16,
                                          fillColor: AppColors.inputFillAlt,
                                          hint: 'Partner 1',
                                          controller: _partner1Ctrl,
                                          validator: _required,
                                          prefixIcon: Icons.person_outline,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 18,
                                          left: 10,
                                          right: 10,
                                        ),
                                        child: Text(
                                          '&',
                                          style: GoogleFonts.playfairDisplay(
                                            fontSize: 20,
                                            color: AppColors.amber,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: WedTextField(
                                          borderRadius: 16,
                                          fillColor: AppColors.inputFillAlt,
                                          hint: 'Partner 2',
                                          controller: _partner2Ctrl,
                                          validator: _required,
                                          prefixIcon: Icons.person_outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ] else ...[
                                WedTextField(
                                  borderRadius: 16,
                                  fillColor: AppColors.inputFillAlt,
                                  hint: 'Business name',
                                  controller: _businessNameCtrl,
                                  validator: _required,
                                  prefixIcon: Icons.store_outlined,
                                ),
                              ],
                              const SizedBox(height: 20),

                              WedTextField(
                                borderRadius: 16,
                                fillColor: AppColors.inputFillAlt,
                                hint: 'Phone number',
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                prefixIcon: Icons.phone_outlined,
                                validator: _required,
                              ),
                              const SizedBox(height: 20),

                              WedTextField(
                                borderRadius: 16,
                                fillColor: AppColors.inputFillAlt,
                                hint: 'Email address',
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.mail_outline,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (!v.contains('@')) return 'Invalid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              WedTextField(
                                borderRadius: 16,
                                fillColor: AppColors.inputFillAlt,
                                hint: 'Password',
                                controller: _passCtrl,
                                isPassword: true,
                                prefixIcon: Icons.lock_outline,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (v.length < 8) return 'Min 8 characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 28),

                              // ── CTA button ─────────────────────────────────
                              WedButton(
                                label: _role == UserRole.couple
                                    ? 'Create our account'
                                    : 'Create account',
                                onPressed: _submit,
                                variant: WedButtonVariant.primaryDark,
                                isLoading: auth.isLoading,
                                height: 56,
                                borderRadius: 16,
                              ),
                              const SizedBox(height: 16),

                              // ── Legal ──────────────────────────────────────
                              Center(
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.textHint,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text:
                                            "By continuing you agree to WedPilot's ",
                                      ),
                                      TextSpan(
                                        text: 'Terms of Service',
                                        style: TextStyle(
                                          color: AppColors.forestGreen,
                                          decoration: TextDecoration.underline,
                                          decorationColor:
                                              AppColors.forestGreen,
                                        ),
                                      ),
                                      TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                          color: AppColors.forestGreen,
                                          decoration: TextDecoration.underline,
                                          decorationColor:
                                              AppColors.forestGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Login link ────────────────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go('/login'),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white60,
                              ),
                              children: const [
                                TextSpan(text: 'Already planning with us? '),
                                TextSpan(
                                  text: 'Log in',
                                  style: TextStyle(
                                    color: AppColors.amber,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
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

// ── Text field ────────────────────────────────────────────────────────────────
