import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wed_plan_pilot/features/auth/screens/couple_planning_screen.dart';

/// Drives the full 5-step wedding planning wizard: budget (incl. a couple-added
/// custom vendor type), date, style, details, then the AI-curated review step.
Future<void> _runWizardFlow(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(home: CouplePlanningScreen()),
    ),
  );
  await tester.pump();

  // ── Step 0: Budget & basics ──────────────────────────────────────────────
  await tester.enterText(find.byType(TextField).at(0), '150000'); // budget
  await tester.enterText(find.byType(TextField).at(1), '120'); // guests
  await tester.enterText(find.byType(TextField).at(2), 'Ndola, Copperbelt'); // location
  await tester.pump();

  await tester.ensureVisible(find.text('Venue'));
  await tester.tap(find.text('Venue'));
  await tester.tap(find.text('Catering'));
  await tester.pump();

  // Add a custom vendor type the fixtures have no match for, then verify
  // it can be removed and re-added.
  await tester.ensureVisible(find.byType(TextField).at(3));
  await tester.enterText(find.byType(TextField).at(3), 'Hair & Makeup');
  await tester.ensureVisible(find.byIcon(Icons.add_rounded));
  await tester.tap(find.byIcon(Icons.add_rounded));
  await tester.pump();
  expect(find.text('Hair & Makeup'), findsOneWidget);

  await tester.ensureVisible(find.byIcon(Icons.close_rounded));
  await tester.tap(find.byIcon(Icons.close_rounded));
  await tester.pump();
  expect(find.text('Hair & Makeup'), findsNothing);

  await tester.enterText(find.byType(TextField).at(3), 'Hair & Makeup');
  await tester.ensureVisible(find.byIcon(Icons.add_rounded));
  await tester.tap(find.byIcon(Icons.add_rounded));
  await tester.pump();
  expect(find.text('Hair & Makeup'), findsOneWidget);

  await tester.ensureVisible(find.text('Continue'));
  await tester.tap(find.text('Continue'));
  await tester.pump();

  // ── Step 1: Date (skip picking — not required to continue) ─────────────
  await tester.ensureVisible(find.text('Continue'));
  await tester.tap(find.text('Continue'));
  await tester.pump();

  // ── Step 2: Style ────────────────────────────────────────────────────────
  await tester.tap(find.text('Elegant'));
  await tester.pump();
  await tester.ensureVisible(find.text('Continue'));
  await tester.tap(find.text('Continue'));
  await tester.pump();

  // ── Step 3: Details → create the plan ───────────────────────────────────
  await tester.ensureVisible(find.text('Create our wedding plan'));
  await tester.tap(find.text('Create our wedding plan'));
  await tester.pump();

  // ── Step 4: AI-curated review ────────────────────────────────────────────
  // Let the mock AI matcher (900ms) and budget generator (250ms) resolve.
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pump();

  // AI matched Venue/Catering from fixtures; Hair & Makeup has no fixture
  // vendors, so it should fall back to the "add your own" prompt.
  expect(find.text('AI top pick'), findsWidgets);
  expect(find.textContaining('No available'), findsOneWidget);
  expect(find.text('Add your own vendor'), findsWidgets);
  expect(find.text('Budget breakdown'), findsOneWidget);
  expect(find.text('Share to WhatsApp & more'), findsOneWidget);
  expect(find.text('Download PDF'), findsOneWidget);
  expect(find.text('Go to Dashboard'), findsOneWidget);

  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('Wedding planning wizard — desktop width, no overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _runWizardFlow(tester);
  });

  testWidgets('Wedding planning wizard — narrow mobile width, no overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _runWizardFlow(tester);
  });
}
