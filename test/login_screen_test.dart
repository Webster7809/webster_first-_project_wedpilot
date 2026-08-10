import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wed_plan_pilot/core/theme/app_colors.dart';
import 'package:wed_plan_pilot/core/theme/app_theme.dart';
import 'package:wed_plan_pilot/features/auth/screens/login_screen.dart';
import 'package:wed_plan_pilot/features/auth/screens/register_screen.dart';
import 'package:wed_plan_pilot/widgets/wed_button.dart';
import 'package:wed_plan_pilot/widgets/wizard_widgets.dart';

/// The Sign In button is the whole point of this screen. These pin down that it
/// is present, on-screen, and hittable at the phone sizes WedPilot targets —
/// the hero section above it has a 280px floor, so any growth in the form
/// (a larger type scale, a taller field) pushes the button toward the fold.
void main() {
  Future<void> pumpLogin(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  // 320x568 is an iPhone SE / small Android; 360x640 the most common Android.
  for (final size in const [Size(320, 568), Size(360, 640), Size(412, 915)]) {
    testWidgets('Sign In button renders at ${size.width}x${size.height}',
        (tester) async {
      await pumpLogin(tester, size);

      final signIn = find.widgetWithText(WedButton, 'Sign In');
      expect(signIn, findsOneWidget, reason: 'Sign In button is missing');

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Sign In is reachable by scrolling on a small phone',
      (tester) async {
    await pumpLogin(tester, const Size(320, 568));

    await tester.dragUntilVisible(
      find.widgetWithText(WedButton, 'Sign In'),
      find.byType(SingleChildScrollView),
      const Offset(0, -120),
    );
    await tester.pump();

    final box = tester.getRect(find.widgetWithText(WedButton, 'Sign In'));
    expect(box.top, greaterThanOrEqualTo(0.0));
    expect(box.bottom, lessThanOrEqualTo(568.0),
        reason: 'Sign In still off-screen after scrolling to it');
  });

  // A gold sweep once converted this same eyebrow to forest-on-forest on three
  // separate screens (login, register, and every onboarding wizard step via
  // the shared WizardHeader) — each escaped detection because the forest fill
  // was declared far enough above the text that a line-distance heuristic
  // missed it. Pinned by widget identity rather than distance so it can't
  // regress the same way twice.
  group('eyebrows on a forest ground are never forest-colored', () {
    testWidgets('login hero', (tester) async {
      await pumpLogin(tester, const Size(360, 640));
      final eyebrow = tester.widget<Text>(find.text('WELCOME BACK'));
      expect(eyebrow.style?.color, isNot(AppColors.forestGreen));
      expect(eyebrow.style?.color, isNot(AppColors.primary));
    });

    testWidgets('register hero', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(theme: AppTheme.light, home: const RegisterScreen()),
        ),
      );
      await tester.pump();

      final eyebrow = tester.widget<Text>(find.text('GET STARTED'));
      expect(eyebrow.style?.color, isNot(AppColors.forestGreen));
      expect(eyebrow.style?.color, isNot(AppColors.primary));

      final loginLink = tester
          .widgetList<RichText>(find.byType(RichText))
          .expand((r) => (r.text as TextSpan).children ?? const [])
          .whereType<TextSpan>()
          .firstWhere((s) => s.text == 'Log in');
      expect(loginLink.style?.color, isNot(AppColors.forestGreen));
      expect(loginLink.style?.color, isNot(AppColors.primary));
    });

    testWidgets('onboarding WizardHeader step label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: WizardHeader(
              step: 0,
              totalSteps: 4,
              stepLabel: 'STEP LABEL',
              stepTitle: 'Step title',
            ),
          ),
        ),
      );
      final eyebrow = tester.widget<Text>(find.text('STEP LABEL'));
      expect(eyebrow.style?.color, isNot(AppColors.forestGreen));
      expect(eyebrow.style?.color, isNot(AppColors.primary));
    });
  });
}
