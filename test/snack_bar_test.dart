import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wed_plan_pilot/core/theme/app_theme.dart';
import 'package:wed_plan_pilot/widgets/wed_snack_bar.dart';

/// `SnackBar.persist` defaults to `action != null` in Flutter, so a bar with
/// an action stays on screen forever: its dismiss timer fires on schedule,
/// sees persist, and returns without hiding. That is invisible in the call
/// site — nothing in `showWedSnackBar(...)` hints at it — and it left the
/// booking UNDO bar sitting over the vendor list indefinitely. Pinned here
/// because a framework default flipping back would otherwise go unnoticed.
void main() {
  Future<void> pumpAndShow(
    WidgetTester tester, {
    String? actionLabel,
    VoidCallback? onAction,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showWedSnackBar(
                  context,
                  'Request sent.',
                  type: SnackType.success,
                  actionLabel: actionLabel,
                  onAction: onAction,
                ),
                child: const Text('show'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    // Let the entrance animation finish — the dismiss timer is only created
    // once the snack bar controller reports completed.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('a snack bar with an action still dismisses itself',
      (tester) async {
    await pumpAndShow(tester, actionLabel: 'UNDO', onAction: () {});
    expect(find.text('Request sent.'), findsOneWidget);

    // 6s is the actionable default; well past it the bar must be gone.
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();

    expect(find.text('Request sent.'), findsNothing,
        reason: 'actionable snack bar never auto-dismissed');
  });

  testWidgets('an actionable snack bar outlives the plain 3s default',
      (tester) async {
    await pumpAndShow(tester, actionLabel: 'UNDO', onAction: () {});

    // Still up at 4s: an UNDO the user has to read, aim at and tap needs
    // longer on screen than a bar they only read.
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Request sent.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Request sent.'), findsNothing);
  });

  testWidgets('a plain snack bar dismisses after its 3s default',
      (tester) async {
    await pumpAndShow(tester);
    expect(find.text('Request sent.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Request sent.'), findsNothing);
  });

  testWidgets('tapping the action dismisses immediately and fires the callback',
      (tester) async {
    var undone = false;
    await pumpAndShow(tester, actionLabel: 'UNDO', onAction: () => undone = true);

    await tester.tap(find.text('UNDO'));
    await tester.pumpAndSettle();

    expect(undone, isTrue);
    expect(find.text('Request sent.'), findsNothing);
  });
}
