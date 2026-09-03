import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wed_plan_pilot/core/services/wedding_ai_service.dart';
import 'package:wed_plan_pilot/core/state/resource.dart';
import 'package:wed_plan_pilot/features/auth/screens/couple_planning_screen.dart';
import 'package:wed_plan_pilot/models/budget.dart';
import 'package:wed_plan_pilot/models/vendor_profile.dart';
import 'package:wed_plan_pilot/providers/budget_provider.dart';
import 'package:wed_plan_pilot/providers/vendor_provider.dart';

/// Stand-in for the vendor pool the real backend would return. Overriding
/// [vendorPoolProvider] (rather than mocking HTTP) keeps this test independent
/// of a running backend and of the couple being signed in — [vendorPoolProvider]
/// is already the seam vendorMatchValidationProvider reads from, so this is
/// the same boundary production code uses, just fed fixed data instead of a
/// network call.
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
    feedbackCount: 42,
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
    feedbackCount: 27,
    compositeScore: 75,
  ),
];

/// Priced fixtures for the budget-realism tests below — [_fakeVendors]
/// deliberately carries no [VendorService] entries (so `priceMin`/`priceMax`
/// are 0), which is fine for the style/category tests but means it can never
/// trigger the "unrealistically small budget" or "closest available tier fit"
/// soft-flagging, which only ever acts on vendors with a real price on file.
final _pricedVendors = [
  const VendorProfile(
    id: 'venue-1',
    userId: 'vendor-1',
    businessName: 'Copperbelt Grand Hall',
    category: 'Venue',
    location: 'Ndola, Copperbelt',
    tier: VendorTier.pro,
    verificationStatus: VerificationStatus.verified,
    rating: 4.6,
    feedbackCount: 42,
    compositeScore: 88,
    services: [
      VendorService(
        id: 'venue-1-svc',
        vendorId: 'venue-1',
        title: 'Full venue package',
        priceMin: 60000,
        priceMax: 90000,
        unit: 'package',
      ),
    ],
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
    feedbackCount: 27,
    compositeScore: 75,
    services: [
      VendorService(
        id: 'catering-1-svc',
        vendorId: 'catering-1',
        title: 'Full catering package',
        priceMin: 45000,
        priceMax: 70000,
        unit: 'package',
      ),
    ],
  ),
];

/// Fixtures for the swap/rescue test below — Venue has *two* real vendors
/// (unlike every other fixture set here, which has exactly one per category,
/// so there's never anything to swap to) so the budget allocator's rescue
/// pass has an actual cheaper alternative to downgrade to when Catering
/// would otherwise run out of room.
final _rescueVendors = [
  const VendorProfile(
    id: 'venue-expensive',
    userId: 'vendor-1a',
    businessName: 'Prestige Manor Estates',
    category: 'Venue',
    location: 'Ndola, Copperbelt',
    tier: VendorTier.premium,
    verificationStatus: VerificationStatus.verified,
    rating: 4.9,
    feedbackCount: 80,
    compositeScore: 95,
    services: [
      VendorService(
        id: 'venue-expensive-svc',
        vendorId: 'venue-expensive',
        title: 'Full venue package',
        priceMin: 60000,
        priceMax: 60000,
        unit: 'package',
      ),
    ],
  ),
  const VendorProfile(
    id: 'venue-cheap',
    userId: 'vendor-1b',
    businessName: 'Budget Hall Ndola',
    category: 'Venue',
    location: 'Ndola, Copperbelt',
    tier: VendorTier.free,
    verificationStatus: VerificationStatus.verified,
    rating: 3.0,
    feedbackCount: 5,
    compositeScore: 40,
    services: [
      VendorService(
        id: 'venue-cheap-svc',
        vendorId: 'venue-cheap',
        title: 'Full venue package',
        priceMin: 50000,
        priceMax: 50000,
        unit: 'package',
      ),
    ],
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
    feedbackCount: 27,
    compositeScore: 75,
    services: [
      VendorService(
        id: 'catering-1-svc',
        vendorId: 'catering-1',
        title: 'Full catering package',
        priceMin: 20000,
        priceMax: 20000,
        unit: 'package',
      ),
    ],
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

/// Regression fixture for a real race condition: [BudgetNotifier.loadBudget]
/// is a fire-and-forget network call, so the saved [Budget] it produces can
/// still hold a stale total (here, 1) from a previous session by the time the
/// validation pipeline first runs. Starts on that stale value and only
/// updates to the freshly-entered total after a delay, so a test can assert
/// the wizard's own [wizardBudgetProvider] — not this notifier — is what the
/// validation actually reads.
class _StaleThenSlowBudgetNotifier extends BudgetNotifier {
  _StaleThenSlowBudgetNotifier(super.ref) {
    state = Resource(
      status: ResourceStatus.ready,
      data: Budget(
        id: 'stale-budget',
        coupleId: 'test-couple',
        totalAmount: 1,
        currency: 'ZMW',
        isAiGenerated: true,
        categories: const [],
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> loadBudget({
    required double total,
    required String currency,
    List<String>? serviceCategories,
    List<BudgetCustomItem>? customItems,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    state = Resource(
      status: ResourceStatus.ready,
      data: Budget(
        id: 'test-budget',
        coupleId: 'test-couple',
        totalAmount: total,
        currency: currency,
        isAiGenerated: true,
        categories: const [],
        createdAt: DateTime.now(),
      ),
    );
  }
}

/// Scrolls [finder] into view and pumps a frame before returning.
///
/// `tester.ensureVisible` jumps the scroll position without pumping, so the
/// render tree still carries the pre-scroll geometry when it returns. A `tap`
/// issued straight afterwards derives its offset from that stale layout, misses
/// the widget, and — because a missed tap is only a printed warning, never a
/// failure — silently does nothing while the test still passes. That is exactly
/// what was happening to the category chips below: neither was ever actually
/// ticked, and the wizard's "no categories selected → fall back to every
/// category" path (see `_activeCategories`) made the assertions pass anyway.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
}

/// Pumps the wizard, fills in Step 0 with the given budget/guests/location,
/// optionally selects a wedding-class card, taps the Venue and Catering
/// category chips, then advances straight through Date/Style to the AI
/// review step (Step 3) and lets the AI/validation providers resolve.
Future<void> _pumpWizardToReviewStep(
  WidgetTester tester, {
  required List<VendorProfile> vendors,
  required String budget,
  required String location,
  String guests = '120',
  String? weddingClass,
  BudgetNotifier Function(Ref ref)? budgetNotifierBuilder,
}) async {
  // See resetQueueForTests' doc comment: WeddingAiService.instance's call
  // queue is a real singleton Future chain that must be reset from inside
  // *this* test's own zone (not from setUp, which runs in a different one)
  // or every AI-reaching test after the first in this file starves forever.
  WeddingAiService.instance.resetQueueForTests();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vendorPoolProvider.overrideWith((ref, categories) async => vendors),
        budgetProvider.overrideWith(
          budgetNotifierBuilder ?? (ref) => _FakeBudgetNotifier(ref),
        ),
      ],
      child: const MaterialApp(home: CouplePlanningScreen()),
    ),
  );
  await tester.pump();

  // ── Step 0: Budget & basics ──────────────────────────────────────────────
  await tester.enterText(find.byType(TextField).at(0), budget);
  await tester.enterText(find.byType(TextField).at(1), guests);
  await tester.enterText(find.byType(TextField).at(2), location);
  await tester.pump();

  if (weddingClass != null) {
    await _scrollTo(tester, find.text(weddingClass));
    await tester.tap(find.text(weddingClass));
    await tester.pump();
  }

  // The vendor-category checklist is collapsed by default (see
  // _CategoryChecklist) — its items don't exist in the tree at all until
  // the header is tapped to expand it.
  await _scrollTo(tester, find.text('Select the services you need'));
  await tester.tap(find.text('Select the services you need'));
  // Let the checklist's 200ms AnimatedSize expansion finish before tapping
  // anything inside it. Both pumps are load-bearing: the first commits the
  // rebuild and *starts* the size animation (AnimatedSize still measures zero
  // height at that point), and only the second advances the clock past its
  // 200ms duration. With just one, the expanded items are laid out at their
  // real coordinates — so `getRect`/`ensureVisible` report them as visible —
  // but sit entirely outside the still-collapsed AnimatedSize's clip, so hit
  // testing never reaches them and every tap below silently lands on the page
  // behind. That failure is invisible without the assertion further down: a
  // missed tap is only a printed warning, and the wizard's "no categories
  // ticked → fall back to every category" path (see `_activeCategories`) left
  // the rest of the flow looking correct anyway.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await _scrollTo(tester, find.text('Venue'));
  await tester.tap(find.text('Venue'));
  await tester.pump();
  await _scrollTo(tester, find.text('Catering'));
  await tester.tap(find.text('Catering'));
  await tester.pump();
  // Guards the taps above rather than the widget: a tap that misses its target
  // is only a printed warning, so without this the whole wizard flow still
  // passes with nothing ticked. See the pump comment above for how that hid a
  // real breakage.
  expect(find.text('2 services selected'), findsOneWidget);
  await _scrollTo(tester, find.text('Continue'));
  await tester.tap(find.text('Continue'));
  await tester.pump();

  // ── Step 1: Date ────────────────────────────────────────────────────────
  await _pickWeddingDate(tester);
  await _scrollTo(tester, find.text('Continue'));
  await tester.tap(find.text('Continue'));
  await tester.pump();

  // ── Step 2: Style → create the plan ─────────────────────────────────────
  await tester.tap(find.text('Elegant'));
  await tester.pump();
  await _scrollTo(tester, find.text('Create our wedding plan'));
  await tester.tap(find.text('Create our wedding plan'));
  await tester.pump();

  // ── Step 3: AI-curated review ────────────────────────────────────────────
  // Let the validation pipeline and AI vendor matcher (falls back to local
  // ranking with no backend reachable) resolve.
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pump();

  if (budgetNotifierBuilder != null) {
    // A custom notifier may resolve its saved Budget after a delay of its
    // own, re-triggering the AI providers — give that settle cycle room too.
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump();
  }
}

/// Drives the full 4-step wedding planning wizard: budget, date, then style
/// (which creates the plan directly — there's no separate details step),
/// then the AI-curated review step.
///
/// Adding a couple-defined custom vendor category used to be part of this
/// flow (an inline text field + add button in Step 0), but that control has
/// since been removed from the UI entirely — category selection is now only
/// the checklist of built-in/vendor-registered categories (see
/// `_CategoryChecklist`). Nothing here exercises that anymore.
Future<void> _runWizardFlow(WidgetTester tester) async {
  // See resetQueueForTests' doc comment: WeddingAiService.instance's call
  // queue is a real singleton Future chain that must be reset from inside
  // *this* test's own zone (not from setUp, which runs in a different one)
  // or every AI-reaching test after the first in this file starves forever.
  WeddingAiService.instance.resetQueueForTests();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vendorPoolProvider.overrideWith((ref, categories) async => _fakeVendors),
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

  // The vendor-category checklist is collapsed by default (see
  // _CategoryChecklist) — its items don't exist in the tree at all until
  // the header is tapped to expand it.
  await _scrollTo(tester, find.text('Select the services you need'));
  await tester.tap(find.text('Select the services you need'));
  // Let the checklist's 200ms AnimatedSize expansion finish before tapping
  // anything inside it. Both pumps are load-bearing: the first commits the
  // rebuild and *starts* the size animation (AnimatedSize still measures zero
  // height at that point), and only the second advances the clock past its
  // 200ms duration. With just one, the expanded items are laid out at their
  // real coordinates — so `getRect`/`ensureVisible` report them as visible —
  // but sit entirely outside the still-collapsed AnimatedSize's clip, so hit
  // testing never reaches them and every tap below silently lands on the page
  // behind. That failure is invisible without the assertion further down: a
  // missed tap is only a printed warning, and the wizard's "no categories
  // ticked → fall back to every category" path (see `_activeCategories`) left
  // the rest of the flow looking correct anyway.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await _scrollTo(tester, find.text('Venue'));
  await tester.tap(find.text('Venue'));
  await tester.pump();
  await _scrollTo(tester, find.text('Catering'));
  await tester.tap(find.text('Catering'));
  await tester.pump();
  // Guards the taps above rather than the widget: a tap that misses its target
  // is only a printed warning, so without this the whole wizard flow still
  // passes with nothing ticked. See the pump comment above for how that hid a
  // real breakage.
  expect(find.text('2 services selected'), findsOneWidget);
  await _scrollTo(tester, find.text('Continue'));
  await tester.tap(find.text('Continue'));
  await tester.pump();

  // ── Step 1: Date ────────────────────────────────────────────────────────
  await _pickWeddingDate(tester);
  await _scrollTo(tester, find.text('Continue'));
  await tester.tap(find.text('Continue'));
  await tester.pump();

  // ── Step 2: Style → create the plan ─────────────────────────────────────
  await tester.tap(find.text('Elegant'));
  await tester.pump();
  await _scrollTo(tester, find.text('Create our wedding plan'));
  await tester.tap(find.text('Create our wedding plan'));
  await tester.pump();

  // ── Step 3: AI-curated review ────────────────────────────────────────────
  // Let the AI vendor matcher (falls back to local ranking with no backend
  // reachable) and the fake budget notifier resolve.
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pump();

  // AI matched both Venue and Catering from the fixtures.
  expect(find.text('AI top pick'), findsNWidgets(2));
  expect(find.text('Download PDF'), findsOneWidget);
  expect(find.text('Go to Dashboard'), findsOneWidget);

  expect(tester.takeException(), isNull);
}

/// Pumps the wizard and advances to Step 2 (Style) — steps 0 and 1 have no
/// bearing on the style-pill behavior under test, so only the minimum needed
/// to reach Style is filled in.
Future<void> _reachStyleStep(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vendorPoolProvider.overrideWith((ref, categories) async => _fakeVendors),
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
  // The vendor-category checklist is collapsed by default (see
  // _CategoryChecklist) — its items don't exist in the tree at all until
  // the header is tapped to expand it.
  await _scrollTo(tester, find.text('Select the services you need'));
  await tester.tap(find.text('Select the services you need'));
  // Let the checklist's 200ms AnimatedSize expansion finish before tapping
  // anything inside it. Both pumps are load-bearing: the first commits the
  // rebuild and *starts* the size animation (AnimatedSize still measures zero
  // height at that point), and only the second advances the clock past its
  // 200ms duration. With just one, the expanded items are laid out at their
  // real coordinates — so `getRect`/`ensureVisible` report them as visible —
  // but sit entirely outside the still-collapsed AnimatedSize's clip, so hit
  // testing never reaches them and every tap below silently lands on the page
  // behind. That failure is invisible without the assertion further down: a
  // missed tap is only a printed warning, and the wizard's "no categories
  // ticked → fall back to every category" path (see `_activeCategories`) left
  // the rest of the flow looking correct anyway.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await _scrollTo(tester, find.text('Venue'));
  await tester.tap(find.text('Venue'));
  await tester.pump();
  // Guards the tap above rather than the widget — see the identical assertion
  // in _pumpWizardToReviewStep for why a missed tap would otherwise pass.
  expect(find.text('1 service selected'), findsOneWidget);

  await _scrollTo(tester, find.text('Continue'));
  await tester.tap(find.text('Continue'));
  await tester.pump();

  // ── Step 1: Date ────────────────────────────────────────────────────────
  await _pickWeddingDate(tester);
  await _scrollTo(tester, find.text('Continue'));
  await tester.tap(find.text('Continue'));
  await tester.pump();

  // Now at Step 2: Style.
}

/// The pill (InkWell) rendering a given style label — its subtree carries a
/// 1ST/2ND badge Text when selected, so this lets a test check a given
/// pill's selection state independent of the others.
Finder _stylePill(String style) => find.widgetWithText(InkWell, style);

/// Opens the step-1 date picker and accepts its initial date.
///
/// The wizard refuses to advance without a wedding date — it decides which
/// vendors are actually free, so a plan built without one is matching against
/// availability it never checked. These helpers used to skip this step, which
/// is exactly why nothing caught that it was skippable.
/// Explicit pumps rather than `pumpAndSettle`: something on this screen
/// animates continuously, so settling never completes — which is why every
/// other helper in this file pumps fixed durations too.
Future<void> _pickWeddingDate(WidgetTester tester) async {
  await _scrollTo(tester, find.text('Tap to pick your date'));
  await tester.tap(find.text('Tap to pick your date'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  await tester.tap(find.text('OK'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  expect(
    find.text('Tap to pick your date'),
    findsNothing,
    reason: 'date picker closed without setting a date',
  );
}

void main() {
  testWidgets('Style step — primary/secondary selection', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _reachStyleStep(tester);

    // Tap 1: Elegant becomes primary.
    await tester.tap(find.text('Elegant'));
    await tester.pump();
    expect(
      find.descendant(of: _stylePill('Elegant'), matching: find.text('1ST')),
      findsOneWidget,
    );
    expect(find.text('2ND'), findsNothing);

    // Tap 2: Modern becomes secondary; Elegant stays primary.
    await tester.tap(find.text('Modern'));
    await tester.pump();
    expect(
      find.descendant(of: _stylePill('Elegant'), matching: find.text('1ST')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _stylePill('Modern'), matching: find.text('2ND')),
      findsOneWidget,
    );

    // Tap 3: Rustic (a third, distinct style) swaps in as the new secondary
    // — Modern reverts to unselected, Elegant is untouched as primary.
    await tester.tap(find.text('Rustic'));
    await tester.pump();
    expect(
      find.descendant(of: _stylePill('Elegant'), matching: find.text('1ST')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _stylePill('Rustic'), matching: find.text('2ND')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _stylePill('Modern'), matching: find.text('2ND')),
      findsNothing,
    );
    expect(
      find.descendant(of: _stylePill('Modern'), matching: find.text('1ST')),
      findsNothing,
    );

    // Tap 4: deselecting the primary (Elegant) auto-promotes Rustic to primary.
    await tester.tap(find.text('Elegant'));
    await tester.pump();
    expect(
      find.descendant(of: _stylePill('Rustic'), matching: find.text('1ST')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _stylePill('Elegant'), matching: find.text('1ST')),
      findsNothing,
    );
    expect(find.text('2ND'), findsNothing);

    expect(tester.takeException(), isNull);
  });

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

  testWidgets(
      'Validation — no vendors anywhere in the entered location blocks the whole plan',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Fixture vendors are all in Ndola, Copperbelt; the couple enters a
    // different location entirely, so there's nothing real to build a plan
    // from — this must hard-stop before any AI call, not just degrade
    // per-category.
    await _pumpWizardToReviewStep(
      tester,
      vendors: _fakeVendors,
      budget: '150000',
      location: 'Solwezi',
    );

    expect(find.text("We couldn't build your plan yet"), findsOneWidget);
    // aiRecommendedVendorsProvider is the sole decision-maker for the review
    // step (see vendor_ai_provider.dart) — a single _VendorValidationFailureCard
    // renders its blocking message, not a separate duplicate summary.
    expect(
      find.textContaining('No vendors are currently available in your selected location'),
      findsOneWidget,
    );
    expect(find.text('Edit requirements'), findsOneWidget);
    expect(find.text('AI top pick'), findsNothing);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Validation — a budget too small for any real vendor rejects the whole plan, no AI shown',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // 18,000 can't afford even the single cheapest real vendor on file
    // (Catering at 45,000) — there's no honest plan to build from real data
    // at this amount, so the AI must never run and the couple sees a clear
    // rejection instead of any vendor cards or reasoning text.
    await _pumpWizardToReviewStep(
      tester,
      vendors: _pricedVendors,
      budget: '18000',
      location: 'Ndola, Copperbelt',
    );

    expect(find.text("We couldn't build your plan yet"), findsOneWidget);
    expect(
      find.textContaining('too small for any vendor we have on file'),
      findsOneWidget,
    );
    expect(find.text('AI top pick'), findsNothing);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Validation — sequential allocation funds earlier categories then says the money ran out',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // 70,000 covers Venue's real price (60,000, funded first — it was
    // selected first) leaving only 10,000 — not enough for Catering's
    // cheapest real vendor (45,000). Venue must still get a real AI pick;
    // Catering must be told plainly the money ran out before reaching it,
    // never silently invented or blocked outright.
    await _pumpWizardToReviewStep(
      tester,
      vendors: _pricedVendors,
      budget: '70000',
      location: 'Ndola, Copperbelt',
    );

    expect(find.text("We couldn't build your plan yet"), findsNothing);
    expect(find.text('AI top pick'), findsOneWidget);
    expect(
      find.textContaining('Cannot proceed — your money ends here'),
      findsOneWidget,
    );
    // Real spend vs. the entered total is spelled out in the wedding-details
    // recap up top (the standalone "Budget summary" block below the matched
    // vendors was removed) — only Venue's 60,000 was actually spent against
    // a 70,000 budget, leaving 10,000.
    expect(find.text('Budget used'), findsOneWidget);
    expect(find.text('Entered amount'), findsNothing);
    expect(find.text('Allocated amount'), findsNothing);
    expect(find.text('ZMW 70,000'), findsOneWidget);
    expect(find.text('ZMW 60,000'), findsOneWidget);
    expect(find.text('Remaining'), findsOneWidget);
    expect(find.text('ZMW 10,000'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Validation — swaps an expensive pick for a cheaper alternative to rescue a later category',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // 75,000 total. Venue's best-reviewed option (Prestige Manor, 60,000)
    // wins on quality alone and would leave only 15,000 — not enough for
    // Catering's 20,000. But Venue also has a cheaper real alternative
    // (Budget Hall, 50,000): downgrading to it frees 10,000, which is enough
    // to fund Catering too. Both categories must end up with a real pick,
    // and the swapped-down Budget Hall — not Prestige Manor — must be the
    // one shown, proving the downgrade actually happened rather than the
    // couple just getting told "no".
    await _pumpWizardToReviewStep(
      tester,
      vendors: _rescueVendors,
      budget: '75000',
      location: 'Ndola, Copperbelt',
    );

    expect(find.text("We couldn't build your plan yet"), findsNothing);
    expect(find.text('AI top pick'), findsNWidgets(2));
    expect(find.textContaining('Cannot proceed'), findsNothing);
    expect(find.text('Budget Hall Ndola'), findsOneWidget);
    expect(find.text('Prestige Manor Estates'), findsNothing);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Validation — a wedding-class tier mismatch still picks the best available vendor, never blocks',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // A single priced vendor per category is always tier "mid" (nothing to
    // compare it against), so "High class" can never find a "high"-tier
    // pick here — but with a generous budget, the couple must still see the
    // sole real vendor in each category as their pick, not a blocked plan.
    await _pumpWizardToReviewStep(
      tester,
      vendors: _pricedVendors,
      budget: '300000',
      location: 'Ndola, Copperbelt',
      weddingClass: 'High class',
    );

    expect(find.text("We couldn't build your plan yet"), findsNothing);
    expect(find.text('AI top pick'), findsNWidgets(2));

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Validation — reads the freshly entered budget, not a stale saved total still in flight',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // The saved Budget starts at a stale total of 1 (as if left over from an
    // earlier session) and only catches up to the real 300,000 entered here
    // after a delay — mirroring production, where `loadBudget` is a
    // fire-and-forget network call. The validation must use what the couple
    // just typed via `wizardBudgetProvider`, not misread the stale saved
    // total in the meantime (which would otherwise reject the whole plan as
    // "too small for any vendor" over a budget of 1).
    await _pumpWizardToReviewStep(
      tester,
      vendors: _pricedVendors,
      budget: '300000',
      location: 'Ndola, Copperbelt',
      budgetNotifierBuilder: (ref) => _StaleThenSlowBudgetNotifier(ref),
    );

    expect(find.text("We couldn't build your plan yet"), findsNothing);
    expect(
      find.textContaining('too small for any vendor we have on file'),
      findsNothing,
    );
    expect(find.text('AI top pick'), findsNWidgets(2));

    expect(tester.takeException(), isNull);
  });
}
