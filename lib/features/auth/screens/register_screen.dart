import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/vendor_category_images.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/auth_shell.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_snack_bar.dart';
import '../../../widgets/wed_text_field.dart';

const TextStyle _legalLink = TextStyle(
  color: AppColors.forestGreen,
  fontWeight: FontWeight.w600,
  decoration: TextDecoration.underline,
  decorationColor: AppColors.forestGreen,
);

/// What signing up actually buys — shown only on the split layout, where the
/// photo pane has room to spare and would otherwise read as a large empty
/// rectangle with a headline in the corner.
const List<AuthBenefit> _benefits = [
  AuthBenefit(
    Icons.verified_outlined,
    'Vetted vendors',
    'Venues, caterers and photographers matched to your budget.',
  ),
  AuthBenefit(
    Icons.savings_outlined,
    'A budget that adds up',
    'Every allocation and expense tracked in one place.',
  ),
  AuthBenefit(
    Icons.mail_outlined,
    'Invites and RSVPs',
    'Send your invitation and watch the replies land live.',
  ),
];

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  UserRole _role = UserRole.couple;

  final _partner1Ctrl = TextEditingController();
  final _partner2Ctrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _partner1Ctrl.dispose();
    _partner2Ctrl.dispose();
    _businessNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // The password field submits on "done" as well as the button, so this can
    // be entered twice in a row — a second register call would hit the backend
    // with the same payload.
    if (ref.read(authProvider).isLoading) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final isCouple = _role == UserRole.couple;
    final name = isCouple
        ? _partner1Ctrl.text.trim()
        : _businessNameCtrl.text.trim();
    await ref
        .read(authProvider.notifier)
        .register(
          name,
          _emailCtrl.text.trim(),
          _passCtrl.text,
          _role,
          partner2Name: isCouple ? _partner2Ctrl.text.trim() : null,
          phone: _phoneCtrl.text.trim(),
        );
    if (!mounted) return;
    final err = ref.read(authProvider).error;
    if (err != null) {
      showWedSnackBar(context, err, type: SnackType.error);
    } else {
      context.go('/verify-email');
    }
  }

  String? _required(String? v) => (v == null || v.isEmpty) ? 'Required' : null;

  String get _roleBlurb => _role == UserRole.couple
      ? 'Set a budget, match with vendors and manage your guest list together.'
      : 'List your services, show your work and get booked by couples nearby.';

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));

    return AuthShell(
      imageUrl: VendorCategoryImages.authHero(width: 1600)[1],
      eyebrow: 'GET STARTED',
      headline: 'Plan the wedding you both deserve',
      benefits: _benefits,
      crossLinkPrompt: 'Already planning with us?',
      crossLinkAction: 'Log in',
      crossLinkRoute: '/login',
      formBuilder: (context, sideBySide) =>
          _form(isLoading: isLoading, sideBySide: sideBySide),
    );
  }

  Widget _form({required bool isLoading, required bool sideBySide}) {
    final isCouple = _role == UserRole.couple;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create your account',
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.forestGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'About a minute to set up. Everything after that is the fun part.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 22),

          _RoleSelector(
            role: _role,
            onChanged: (role) => setState(() => _role = role),
          ),
          const SizedBox(height: 10),
          Text(
            _roleBlurb,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),

          if (isCouple) ...[
            if (sideBySide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _partnerField(1, _partner1Ctrl)),
                  const SizedBox(width: 14),
                  Expanded(child: _partnerField(2, _partner2Ctrl)),
                ],
              )
            else ...[
              _partnerField(1, _partner1Ctrl),
              const SizedBox(height: 18),
              _partnerField(2, _partner2Ctrl),
            ],
          ] else
            WedTextField(
              label: 'Business name',
              hint: 'e.g. Amara Events',
              controller: _businessNameCtrl,
              validator: _required,
              prefixIcon: Icons.storefront_outlined,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
          const SizedBox(height: 18),

          WedTextField(
            label: 'Phone number',
            hint: '+260 97 000 0000',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            textInputAction: TextInputAction.next,
            validator: _required,
          ),
          const SizedBox(height: 18),

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
            // The rule lives in the hint rather than a helperText: helperText
            // is swapped out for the error slot the moment validation fails,
            // which moves every control below it by a line.
            hint: 'At least 8 characters',
            controller: _passCtrl,
            isPassword: true,
            prefixIcon: Icons.lock_outlined,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (v.length < 8) return 'Min 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 26),

          WedButton(
            label: 'Create account',
            onPressed: _submit,
            variant: WedButtonVariant.primaryDark,
            isLoading: isLoading,
            borderRadius: 28,
          ),
          const SizedBox(height: 22),

          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textHint,
                  height: 1.6,
                ),
                children: const [
                  TextSpan(text: "By continuing you agree to WedPilot's "),
                  TextSpan(text: 'Terms of Service', style: _legalLink),
                  TextSpan(text: ' and '),
                  TextSpan(text: 'Privacy Policy', style: _legalLink),
                  TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _partnerField(int index, TextEditingController controller) {
    return WedTextField(
      label: 'Partner $index',
      hint: 'First name',
      controller: controller,
      validator: _required,
      prefixIcon: Icons.person_outlined,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
    );
  }
}

// ── Role selector ─────────────────────────────────────────────────────────────

/// Couple / Vendor, as a segmented control rather than a `TabBar`.
///
/// A tab bar promises a swipeable page underneath it; this only swaps two
/// fields, so a segmented control describes what actually happens — and leaves
/// room for the icon and the blurb that tell a first-time visitor which side
/// they are on.
class _RoleSelector extends StatelessWidget {
  final UserRole role;
  final ValueChanged<UserRole> onChanged;

  const _RoleSelector({required this.role, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleTab(
              icon: Icons.favorite_outlined,
              label: 'Couple',
              selected: role == UserRole.couple,
              onTap: () => onChanged(UserRole.couple),
            ),
          ),
          Expanded(
            child: _RoleTab(
              icon: Icons.storefront_outlined,
              label: 'Vendor',
              selected: role == UserRole.vendor,
              onTap: () => onChanged(UserRole.vendor),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.forestGreen : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        elevation: selected ? 1 : 0,
        shadowColor: AppColors.cardShadow,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
}
