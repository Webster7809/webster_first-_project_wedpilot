import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wed_plan_pilot/core/services/auth_service.dart';
import 'package:wed_plan_pilot/core/theme/app_theme.dart';
import 'package:wed_plan_pilot/features/auth/screens/email_verify_screen.dart';
import 'package:wed_plan_pilot/providers/auth_provider.dart';
import 'package:wed_plan_pilot/widgets/wed_button.dart';

/// `AuthService` has a private constructor, so there is no faking it from a
/// test library — the seam is one level up, at the notifier. Overriding the
/// two methods here keeps every case below off the network entirely.
class _FakeAuthNotifier extends AuthNotifier {
  // Takes the Ref explicitly: AuthNotifier needs one to drop per-account
  // provider caches when the signed-in identity changes, and the field it
  // stores it in is private, so a super-parameter can't reach it.
  _FakeAuthNotifier(
    Ref ref, {
    this.verifyResult = true,
    this.resendResult = true,
  }) : super(AuthService.instance, ref);

  final bool verifyResult;
  final bool resendResult;

  int verifyCalls = 0;
  int resendCalls = 0;

  @override
  Future<bool> verifyEmail(String token) async {
    verifyCalls++;
    if (!verifyResult) {
      state = state.copyWith(
        error: 'This verification link is invalid or has expired.',
      );
    }
    return verifyResult;
  }

  @override
  Future<bool> resendVerificationEmail() async {
    resendCalls++;
    if (!resendResult) {
      state = state.copyWith(error: 'Could not send the verification email.');
    }
    return resendResult;
  }
}

void main() {
  Future<_FakeAuthNotifier> pumpVerify(
    WidgetTester tester, {
    String? token,
    bool verifyResult = true,
    bool resendResult = true,
  }) async {
    // Built inside the override so it gets a real Ref; captured here so the
    // test can still assert on its call counts afterwards.
    late _FakeAuthNotifier fake;

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) {
            fake = _FakeAuthNotifier(
              ref,
              verifyResult: verifyResult,
              resendResult: resendResult,
            );
            return fake;
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: EmailVerifyScreen(token: token),
        ),
      ),
    );
    await tester.pump();
    return fake;
  }

  Future<void> teardown(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  group('a confirmation link', () {
    testWidgets('redeems its token and reports success', (tester) async {
      final fake = await pumpVerify(tester, token: 'a-good-token');
      await tester.pump();

      expect(fake.verifyCalls, 1);
      expect(find.text('All done'), findsOneWidget);
      expect(find.text('Check your inbox'), findsNothing);
      await teardown(tester);
    });

    testWidgets('surfaces the backend message when the token is rejected',
        (tester) async {
      await pumpVerify(tester, token: 'expired', verifyResult: false);
      await tester.pump();

      expect(find.text('Confirmation failed'), findsOneWidget);
      expect(
        find.textContaining('invalid or has expired'),
        findsWidgets,
        reason: "the backend's reason should reach the user, not a generic one",
      );
      await teardown(tester);
    });

    testWidgets('an empty token is treated as no token, not a failed one',
        (tester) async {
      final fake = await pumpVerify(tester, token: '');
      await tester.pump();

      expect(fake.verifyCalls, 0);
      expect(find.text('Check your inbox'), findsOneWidget);
      await teardown(tester);
    });
  });

  group('the post-signup screen', () {
    testWidgets('holds resend behind a cooldown, then actually sends',
        (tester) async {
      final fake = await pumpVerify(tester);

      // Register has already sent one, so the cooldown starts on arrival.
      final locked = tester.widget<WedButton>(
        find.widgetWithText(WedButton, 'Resend in 60s'),
      );
      expect(locked.onPressed, isNull);

      for (var i = 0; i < 61; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      expect(find.widgetWithText(WedButton, 'Resend email'), findsOneWidget);
      await tester.tap(find.widgetWithText(WedButton, 'Resend email'));
      await tester.pump();

      expect(fake.resendCalls, 1);
      await teardown(tester);
    });

    testWidgets('a failed send does not start the cooldown', (tester) async {
      final fake = await pumpVerify(tester, resendResult: false);

      for (var i = 0; i < 61; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.tap(find.widgetWithText(WedButton, 'Resend email'));
      await tester.pump();

      expect(fake.resendCalls, 1);
      expect(
        find.widgetWithText(WedButton, 'Resend email'),
        findsOneWidget,
        reason: 'a send that failed should leave the button tappable, not '
            'lock it for another minute',
      );
      await teardown(tester);
    });
  });
}
