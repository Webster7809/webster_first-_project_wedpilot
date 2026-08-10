import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import 'wed_snack_bar.dart';

/// "Continue with Google" — an alternate to the email/password form. [role]
/// only matters the first time this Google account is seen (decides the new
/// account's role); an existing account keeps whatever role it already has.
class GoogleSignInButton extends ConsumerWidget {
  final UserRole role;
  final bool isLoading;

  const GoogleSignInButton({super.key, required this.role, this.isLoading = false});

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).loginWithGoogle(role);
    if (!context.mounted) return;
    final error = ref.read(authProvider).error;
    if (error != null) showWedSnackBar(context, error, type: SnackType.error);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : () => _handleTap(context, ref),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.divider),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _GoogleMark(),
            const SizedBox(width: 10),
            // Flexible + FittedBox, not a bare Text: at large text-scale
            // settings on a 320pt phone this label is wider than the button,
            // and the whole point of the label is that it stays readable.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Continue with Google',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
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

/// A plain "G" mark, not the licensed Google logo asset — good enough for a
/// scaffolded button; swap in the real multi-color "G" asset once this is
/// wired up to a real OAuth client (see GOOGLE_SIGNIN_SETUP.md).
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.textSecondary, width: 1.2),
      ),
      child: Text(
        'G',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          height: 1,
        ),
      ),
    );
  }
}

/// A thin "or" divider between the email/password form and the Google
/// button — same look on both the login and register screens.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }
}
