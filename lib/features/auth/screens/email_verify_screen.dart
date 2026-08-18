import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/vendor_category_images.dart';
import '../../../core/router/app_routes.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/auth_shell.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_snack_bar.dart';

/// Seconds before "Resend email" becomes tappable again. Register already
/// sends one, so the cooldown starts on arrival rather than on first tap.
const int _resendCooldown = 60;

enum _Phase {
  /// No token in the URL — this is the post-signup "we've emailed you" step.
  inbox,

  /// A token is being redeemed against the backend.
  verifying,

  /// The address is confirmed.
  verified,

  /// The token was rejected — expired, already used, or malformed.
  failed,
}

/// Two screens in one, chosen by whether the route carries a `token`:
///
/// * `/verify-email` — the step after signup. Says which address the link went
///   to and offers a resend.
/// * `/verify-email?token=…` — where the emailed link lands. Redeems the token
///   and reports the outcome. Reachable without a session (see the router's
///   redirect), because the link opens in whatever browser the user's mail
///   client hands it to.
class EmailVerifyScreen extends ConsumerStatefulWidget {
  final String? token;

  const EmailVerifyScreen({super.key, this.token});

  @override
  ConsumerState<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends ConsumerState<EmailVerifyScreen> {
  late _Phase _phase;
  String? _failure;

  int _countdown = _resendCooldown;
  Timer? _timer;

  bool get _hasToken => widget.token != null && widget.token!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _phase = _hasToken ? _Phase.verifying : _Phase.inbox;

    if (_hasToken) {
      // Post-frame: redeeming writes to authProvider, and a provider must not
      // be mutated while the tree is still building.
      WidgetsBinding.instance.addPostFrameCallback((_) => _redeem());
    } else {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    // A `Timer`, not the `while (mounted) await Future.delayed(...)` loop this
    // used to run: that loop kept ticking for up to a second after the screen
    // was gone, and nothing could cancel it.
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = _resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _countdown = 0);
        return;
      }
      setState(() => _countdown--);
    });
  }

  Future<void> _redeem() async {
    final ok = await ref.read(authProvider.notifier).verifyEmail(widget.token!);
    if (!mounted) return;
    setState(() {
      _phase = ok ? _Phase.verified : _Phase.failed;
      _failure = ok ? null : ref.read(authProvider).error;
    });
  }

  Future<void> _resend() async {
    final ok = await ref.read(authProvider.notifier).resendVerificationEmail();
    if (!mounted) return;
    if (ok) {
      showWedSnackBar(
        context,
        'Sent — check your inbox again in a moment.',
        type: SnackType.success,
      );
      _startCountdown();
    } else {
      showWedSnackBar(
        context,
        ref.read(authProvider).error ?? 'Could not send that email.',
        type: SnackType.error,
      );
    }
  }

  /// Where "continue" goes. A signed-in user carries on into the app; someone
  /// who opened the link on a device with no session has to log in first.
  void _continue() {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      context.go(AppRoutes.login);
      return;
    }
    context.go(
      auth.user?.role == UserRole.vendor
          ? AppRoutes.vendorOnboarding
          : AppRoutes.couplePlanning,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final email = auth.user?.email;
    final canResend = _countdown == 0;

    // The hero headline and the status title are both on screen at once, so
    // they say different things — repeating the same sentence twice reads
    // like a rendering bug.
    final (eyebrow, headline, support) = switch (_phase) {
      _Phase.verifying => (
          'ALMOST THERE',
          'Checking your link',
          'One moment while we match it to your account.',
        ),
      _Phase.verified => (
          'VERIFIED',
          'Your email is confirmed',
          'That is the last of the admin — time for the good part.',
        ),
      _Phase.failed => (
          'LINK PROBLEM',
          "That link didn't work",
          'Verification links expire after 24 hours and can only be used once.',
        ),
      _Phase.inbox => (
          'ONE LAST STEP',
          'Confirm your email address',
          'Verifying keeps your plans, guest list and vendor conversations '
              'tied to an address only you control.',
        ),
    };

    return AuthShell(
      // The same photograph as the register screen — this is the step
      // immediately after it, and a different image would read as a different
      // product mid-signup.
      imageUrl: VendorCategoryImages.authHero(width: 1600)[1],
      eyebrow: eyebrow,
      headline: headline,
      supportLine: support,
      crossLinkPrompt: 'Wrong account?',
      // Signed in already, so "log in" would be bounced straight back by the
      // router — signing out first is what actually gets you to the login
      // screen. Without a session there is nothing to sign out of.
      crossLinkAction: auth.isAuthenticated ? 'Log out' : 'Log in',
      crossLinkRoute: AppRoutes.login,
      crossLinkOnTap: auth.isAuthenticated
          ? () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            }
          : null,
      formBuilder: (context, _) => switch (_phase) {
        _Phase.verifying => const AuthStatus(
            icon: Icons.mark_email_read_outlined,
            tone: AuthStatusTone.pending,
            busy: true,
            title: 'Confirming your email',
            message: 'This only takes a moment.',
          ),
        _Phase.verified => AuthStatus(
            icon: Icons.check_circle_outlined,
            tone: AuthStatusTone.success,
            title: 'All done',
            message: email == null
                ? 'Your email address is verified.'
                : '$email is verified. Your account is fully active.',
            actions: [
              WedButton(
                label: auth.isAuthenticated ? 'Start planning' : 'Go to log in',
                onPressed: _continue,
                variant: WedButtonVariant.primaryDark,
                borderRadius: 28,
              ),
            ],
          ),
        _Phase.failed => AuthStatus(
            icon: Icons.link_off_outlined,
            tone: AuthStatusTone.error,
            title: 'Confirmation failed',
            // "verification link", matching both the backend's own error
            // string (which lands in _failure and shows here most of the time)
            // and the rest of the app — is_verified, /verify-email, "I've
            // verified".
            message: _failure ??
                'This verification link is invalid or has expired. Send '
                    'yourself a fresh one.',
            actions: [
              // Only offered with a session: resend mails the signed-in
              // account's own address, so there is nothing to send to when the
              // link was opened on a logged-out device.
              if (auth.isAuthenticated)
                WedButton(
                  label: 'Send a new link',
                  onPressed: _resend,
                  variant: WedButtonVariant.primaryDark,
                  isLoading: auth.isLoading,
                  borderRadius: 28,
                ),
              WedButton(
                label: 'Back to log in',
                onPressed: () => context.go(AppRoutes.login),
                variant: auth.isAuthenticated
                    ? WedButtonVariant.secondary
                    : WedButtonVariant.primaryDark,
                borderRadius: 28,
              ),
            ],
          ),
        _Phase.inbox => AuthStatus(
            icon: Icons.mark_email_unread_outlined,
            tone: AuthStatusTone.pending,
            title: 'Check your inbox',
            message: email == null
                ? 'We sent you a verification link. Open it to activate your '
                    'account, then come back here.'
                : 'We sent a verification link to $email. Open it to activate '
                    'your account, then come back here.',
            actions: [
              WedButton(
                label: "I've verified — continue",
                onPressed: _continue,
                variant: WedButtonVariant.primaryDark,
                borderRadius: 28,
              ),
              WedButton(
                label: canResend ? 'Resend email' : 'Resend in ${_countdown}s',
                onPressed: canResend ? _resend : null,
                variant: WedButtonVariant.secondary,
                isLoading: auth.isLoading,
                borderRadius: 28,
              ),
            ],
          ),
      },
    );
  }
}
