import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/config/api_config.dart';
import '../core/services/google_web_button.dart';
import '../core/theme/app_colors.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import 'wed_snack_bar.dart';

/// "Continue with Google" — an alternate to the email/password form. [role]
/// only matters the first time this Google account is seen (decides the new
/// account's role); an existing account keeps whatever role it already has.
class GoogleSignInButton extends ConsumerStatefulWidget {
  final UserRole role;
  final bool isLoading;

  const GoogleSignInButton({super.key, required this.role, this.isLoading = false});

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  // Whether Google is configured is a build-time constant, so this never
  // changes across the widget's lifetime.
  bool get _useWebGoogleButton =>
      kIsWeb && ApiConfig.googleServerClientId.isNotEmpty;

  StreamSubscription<String>? _webSignInSubscription;

  @override
  void initState() {
    super.initState();
    // Google's SDK owns the click on its own rendered button (built in
    // build() below) rather than returning from an awaited call, so sign-in
    // completes here instead of in _handleTap.
    if (_useWebGoogleButton) {
      unawaited(ensureGoogleWebInitialized());
      _webSignInSubscription = googleWebIdTokenEvents.listen(
        (idToken) => ref
            .read(authProvider.notifier)
            .completeGoogleSignIn(idToken, widget.role),
      );
    }
  }

  @override
  void dispose() {
    _webSignInSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    await ref.read(authProvider.notifier).loginWithGoogle(widget.role);
    if (!context.mounted) return;
    final error = ref.read(authProvider).error;
    if (error != null) showWedSnackBar(context, error, type: SnackType.error);
  }

  @override
  Widget build(BuildContext context) {
    if (_useWebGoogleButton) {
      // Google's own button, required on web — see google_web_button_web.dart.
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth =
                  constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;
              return renderGoogleWebButton(minimumWidth: maxWidth.clamp(1, 400));
            },
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: widget.isLoading ? null : () => _handleTap(context, ref),
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

/// Google's official multi-color "G" logomark (see
/// assets/branding/google_logo.svg), sized per Google's Sign In branding
/// guidelines (https://developers.google.com/identity/branding-guidelines).
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/branding/google_logo.svg',
      width: 20,
      height: 20,
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
