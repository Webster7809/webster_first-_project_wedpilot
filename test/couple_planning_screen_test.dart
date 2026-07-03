import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wed_plan_pilot/core/state/resource.dart';
import 'package:wed_plan_pilot/features/auth/screens/couple_planning_screen.dart';
import 'package:wed_plan_pilot/models/budget.dart';
import 'package:wed_plan_pilot/models/vendor_profile.dart';
import 'package:wed_plan_pilot/providers/budget_provider.dart';
import 'package:wed_plan_pilot/providers/vendor_provider.dart';

/// Stand-in for the vendor pool the real backend would return. Overriding
/// [allVendorsProvider] (rather than mocking HTTP) keeps this test independent
/// of a running backend and of the couple being signed in — [allVendorsProvider]
/// is already the seam the AI matcher reads from, so this is the same boundary
/// production code uses, just fed fixed data instead of a network call.
final _fakeVendors = [
  const VendorProfile(
    id: 'venue-1',
    userId: 'vendor-1',
    businessName: 'Copperbelt Grand Hall',
    category: 'Venue',
    location: 'Ndola, Copperbelt',
    tier: VendorTier.pro,
    verificationStatus: VerificationStatus.verified,
    rating: 4.6,
    reviewCount: 42,
    compositeScore: 88,
  ),
  const VendorProfile(
    id: 'catering-1',
    userId: 'vendor-2',
    businessName: 'Zambezi Catering Co.',
    category: 'Catering',
    location: 'Ndola, Copperbelt',
    tier: VendorTier.free,
    verificationStatus: VerificationStatus.verified,
    rating: 4.2,
    reviewCount: 27,
    compositeScore: 75,
  ),
];

/// Stand-in for [BudgetNotifier] that skips the real backend call
/// [BudgetNotifier.loadBudget] would otherwise make, and instead resolves
/// straight to a ready [Budget] — mirroring what the wizard expects once the
/// couple finishes step 3.
class _FakeBudgetNotifier extends BudgetNotifier {
  _FakeBudgetNotifier(super.ref);

  @override
  Future<void> loadBudget({
    required double total,
    required String currency,
    List<String>? serviceCategories,
    List<BudgetCustomItem>? customItems,
  }) async {
    state = Resource(
      status: ResourceStatus.ready,
      data: Budget(
        id: 'test-budget',
        coupleId: 'test-couple',
        totalAmount: total,
        currency: currency,
        isAiGenerated: true,
        categories: const [
          BudgetCategory(
            id: 'cat-venue',
            budgetId: 'test-budget',
            categoryName: 'Venue',
            categoryIcon: '🏛️',
            allocatedAmount: 60000,
            spentAmount: 0,
          ),
          BudgetCategory(
            id: 'cat-catering',
            budgetId: 'test-budget',
            categoryName: 'Catering',
            categoryIcon: '🍽️',
            allocatedAmount: 45000,
            spentAmount: 0,
          ),
        ],
        createdAt: DateTime.now(),
      ),
    );
  }
}

/// Drives the full 5-step wedding planning wizard: budget (incl. a couple-added
/// custom vendor type), date, style, details, then the AI-curated review step.
Future<void> _runWizardFlow(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        allVendorsProvider.overrideWith((ref) async => _fakeVendors),
        budgetProvider.overrideWith((ref) => _FakeBudgetNotifier(ref)),
      ],
      child: const MaterialApp(home: CouplePlanningScreen()),
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
  // Let the AI vendor matcher (falls back to local ranking with no backend
  // reachable) and the fake budget notifier resolve.
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pump();

  // AI matched Venue/Catering from fixtures; Hair & Makeup has no fixture
  // vendors, so it should fall back to the "add your own" prompt.
  expect(find.text('AI top pick'), findsWidgets);
  expect(find.textContaining('No available'), findsOneWidget);
  expect(find.text('Add your own vendor'), findsWidgets);
  expect(find.text('Budget breakdown'), findsOneWidget);
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
