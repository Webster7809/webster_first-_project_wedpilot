import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _formKey = GlobalKey<FormState>();

  // Couple fields
  final _partner1Ctrl = TextEditingController();
  final _partner2Ctrl = TextEditingController();
  // Vendor field
  final _businessNameCtrl = TextEditingController();
  // Shared
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
    await ref.read(authProvider.notifier).register(
          name,
          _emailCtrl.text.trim(),
          _passCtrl.text,
          _role,
          partner2Name: _role == UserRole.couple ? _partner2Ctrl.text.trim() : null,
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

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: AppColors.forestGreen,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.favorite, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text('WedPilot',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                  ],
                ),
                const SizedBox(height: 28),

                // Label + Headline
                Text('PLAN TOGETHER',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amber,
                      letterSpacing: 1.5,
                    )),
                const SizedBox(height: 8),
                Text('Start planning the\nwedding you both want',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    )),
                const SizedBox(height: 28),

                // Tab row
                Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white24)),
                  ),
                  child: TabBar(
                    controller: _tab,
                    isScrollable: false,
                    dividerColor: Colors.transparent,
                    indicator: const UnderlineTabIndicator(
                      borderSide: BorderSide(color: AppColors.amber, width: 2),
                    ),
                    labelColor: AppColors.amber,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: GoogleFonts.inter(fontSize: 15),
                    tabs: const [
                      Tab(text: "I'm a couple"),
                      Tab(text: "I'm a vendor"),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Fields
                if (_role == UserRole.couple) ...[
                  Row(
                    children: [
                      Expanded(child: _GreenField(label: 'Partner 1 name', hint: 'Chanda', controller: _partner1Ctrl, validator: _required)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text('&', style: GoogleFonts.playfairDisplay(fontSize: 20, color: AppColors.amber, fontWeight: FontWeight.w600)),
                      ),
                      Expanded(child: _GreenField(label: 'Partner 2 name', hint: 'Mwila', controller: _partner2Ctrl, validator: _required)),
                    ],
                  ),
                ] else ...[
                  _GreenField(label: 'Business name', hint: 'Mukuba Gardens', controller: _businessNameCtrl, validator: _required),
                ],
                const SizedBox(height: 14),
                _GreenField(
                  label: 'Phone number',
                  hint: '+260 9X XXX XXXX',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                _GreenField(
                  label: 'Email address',
                  hint: 'you@email.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _GreenField(
                  label: 'Create password',
                  hint: '••••••••',
                  controller: _passCtrl,
                  isPassword: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 8) return 'Min 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // CTA
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      elevation: 0,
                    ),
                    child: auth.isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            _role == UserRole.couple ? 'Create our account' : 'Create your account',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Legal
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white54),
                      children: [
                        const TextSpan(text: "By continuing you agree to WedPilot's "),
                        TextSpan(text: 'Terms of Service', style: const TextStyle(color: AppColors.amber, decoration: TextDecoration.underline)),
                        const TextSpan(text: ' and '),
                        TextSpan(text: 'Privacy Policy', style: const TextStyle(color: AppColors.amber, decoration: TextDecoration.underline)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Login link
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/login'),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.white60),
                        children: [
                          const TextSpan(text: 'Already planning with us? '),
                          TextSpan(
                            text: 'Log in',
                            style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? v) => (v == null || v.isEmpty) ? 'Required' : null;
}

class _GreenField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool isPassword;

  const _GreenField({
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.isPassword = false,
  });

  @override
  State<_GreenField> createState() => _GreenFieldState();
}

class _GreenFieldState extends State<_GreenField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70)),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.isPassword && _obscure,
          validator: widget.validator,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 14),
            filled: true,
            fillColor: Colors.white.withAlpha(18),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error, width: 1.5),
            ),
            errorStyle: GoogleFonts.inter(color: const Color(0xFFFF8A80), fontSize: 11),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white38, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
