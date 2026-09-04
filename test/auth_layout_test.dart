import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wed_plan_pilot/core/theme/app_theme.dart';
import 'package:wed_plan_pilot/features/auth/screens/email_verify_screen.dart';
import 'package:wed_plan_pilot/features/auth/screens/forgot_password_screen.dart';
import 'package:wed_plan_pilot/features/auth/screens/login_screen.dart';
import 'package:wed_plan_pilot/features/auth/screens/register_screen.dart';
import 'package:wed_plan_pilot/features/auth/screens/reset_password_screen.dart';
import 'package:wed_plan_pilot/widgets/wed_button.dart';

/// Every signed-out screen renders three different ways off one `AuthShell` —
/// a phone sheet, a tablet card, and a laptop split pane. These pin that each
/// branch lays out without overflowing and still reaches its CTA, at the
/// default type scale and at the largest one `AppSettings.fontSize` can ask
/// for.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget screen,
    Size size, {
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: screen,
        ),
      ),
    );
    await tester.pump();
  }

  /// Tears the screen down inside the test body. EmailVerifyScreen holds a
  /// periodic timer that only its `dispose` cancels, and the binding fails a
  /// test that ends with one still pending.
  Future<void> teardown(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  const sizes = <String, Size>{
    'iPhone SE': Size(320, 568),
    'Android (common)': Size(360, 800),
    'iPhone 14': Size(390, 844),
    'Pixel': Size(412, 915),
    'iPad portrait': Size(768, 1024),
    'small laptop': Size(1280, 800),
    'laptop': Size(1440, 900),
    'short laptop window': Size(1440, 600),
  };

  const screens = <String, (Widget, String)>{
    'register': (RegisterScreen(), 'Create account'),
    'login': (LoginScreen(), 'Sign In'),
    'forgot password': (ForgotPasswordScreen(), 'Send reset link'),
    'reset password': (
      ResetPasswordScreen(token: 'test-token'),
      'Save new password',
    ),
    'verify email': (EmailVerifyScreen(), "I've verified — continue"),
  };

  for (final screen in screens.entries) {
    final (widget, cta) = screen.value;

    group('${screen.key} lays out without overflow', () {
      for (final size in sizes.entries) {
        for (final scale in const [1.0, 1.3]) {
          testWidgets('${size.key} @ ${scale}x', (tester) async {
            await pump(tester, widget, size.value, textScale: scale);
            expect(tester.takeException(), isNull);
            expect(find.widgetWithText(WedButton, cta), findsOneWidget);
            await teardown(tester);
          });
        }
      }
    });

    testWidgets('${screen.key} CTA is reachable by scrolling on the smallest phone',
        (tester) async {
      await pump(tester, widget, const Size(320, 568));

      await tester.dragUntilVisible(
        find.widgetWithText(WedButton, cta),
        find.byType(SingleChildScrollView),
        const Offset(0, -140),
      );
      await tester.pump();

      final box = tester.getRect(find.widgetWithText(WedButton, cta));
      expect(box.top, greaterThanOrEqualTo(0.0));
      expect(box.bottom, lessThanOrEqualTo(568.0));
      await teardown(tester);
    });
  }

  group('layout branch', () {
    testWidgets('a laptop gets the split pane with its extra hero copy',
        (tester) async {
      await pump(tester, const RegisterScreen(), const Size(1440, 900));
      expect(find.text('Vetted vendors'), findsOneWidget);

      await pump(tester, const LoginScreen(), const Size(1440, 900));
      expect(find.textContaining('exactly where you left them'), findsOneWidget);
    });

    testWidgets('a phone gets the stacked sheet, hero copy trimmed',
        (tester) async {
      await pump(tester, const RegisterScreen(), const Size(390, 844));
      expect(find.text('Vetted vendors'), findsNothing);

      await pump(tester, const LoginScreen(), const Size(390, 844));
      expect(find.textContaining('exactly where you left them'), findsNothing);
    });

    testWidgets('a wide but short window falls back to the stacked sheet',
        (tester) async {
      // 1440 clears the width bar; 600 does not clear the height one, and the
      // split pane has no scroll view to absorb the difference.
      await pump(tester, const RegisterScreen(), const Size(1440, 600));
      expect(find.text('Vetted vendors'), findsNothing);
    });
  });

  group('role selector', () {
    testWidgets('swaps the couple fields for the vendor field', (tester) async {
      await pump(tester, const RegisterScreen(), const Size(390, 844));

      expect(find.text('Partner 1'), findsOneWidget);
      expect(find.text('Business name'), findsNothing);

      await tester.tap(find.text('Vendor'));
      await tester.pump();

      expect(find.text('Partner 1'), findsNothing);
      expect(find.text('Business name'), findsOneWidget);
      expect(find.widgetWithText(WedButton, 'Create account'), findsOneWidget);
    });
  });

  group('reset password link states', () {
    for (final token in const [null, '']) {
      testWidgets('a ${token == null ? 'missing' : 'blank'} token shows the '
          'invalid-link view, not the form', (tester) async {
        await pump(
          tester,
          ResetPasswordScreen(token: token),
          const Size(390, 844),
        );

        expect(find.text('Invalid reset link'), findsOneWidget);
        expect(find.widgetWithText(WedButton, 'Request a new link'),
            findsOneWidget);
        expect(find.widgetWithText(WedButton, 'Save new password'), findsNothing);
      });
    }
  });
}
