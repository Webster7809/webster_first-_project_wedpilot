import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget_class.dart';
import '../models/vendor_profile.dart';
import '../models/vendor_validation.dart';
import '../core/services/budget_validation_service.dart';
import '../core/services/couple_profile_service.dart';
import '../core/services/guest_capacity_validation_service.dart';
import '../core/services/location_validation_service.dart';
import '../core/services/vendor_filtering_service.dart';
import '../core/services/wedding_ai_service.dart';
import '../core/utils/format_utils.dart';
import '../core/utils/geo_utils.dart';
import 'auth_provider.dart';
import 'booking_provider.dart';
import 'budget_provider.dart';
import 'invitation_provider.dart' show effectiveGuestCountProvider;
import 'vendor_provider.dart';

export '../models/budget_class.dart';
export '../models/vendor_validation.dart';
export '../core/services/wedding_ai_service.dart' show VendorMatchSuggestion;

/// Currency-scale tolerance for every "does this price fit the budget"
/// comparison below (sequential funding, the final funded-pool filter,
/// over-budget scoring, and budget-realism re-checks) — applied identically
/// across every [BudgetClass]. [remaining]/[categoryBudget] are the result of
/// repeated floating-point subtraction across however many categories were
/// funded before this one, so a couple whose entered budget is *exactly*
/// equal to a vendor's price can otherwise land a few hundredths off after
/// that arithmetic and get wrongly rejected as "too expensive" — a vendor
/// priced at or within a cent of what's available must always count as
/// affordable, never just strictly under.
const _kBudgetEpsilon = 0.01;

/// Stage-by-stage wall-clock timing for one matching run, printed as a
/// single aligned block once the run finishes (debug builds only — see
/// [_StageTimer.report]). Exists so a real slowdown can be *pinpointed*
/// (network fetch vs. local filtering vs. the AI call itself) instead of
/// guessed at — "matching feels slow" alone doesn't say which of those it is.
class _StageTimer {
  final _stopwatch = Stopwatch()..start();
  final List<(String, int)> _laps = [];

  void lap(String label) {
    _laps.add((label, _stopwatch.elapsedMilliseconds));
    _stopwatch.reset();
  }

  void report(String title) {
    if (!kDebugMode) return;
    final total = _laps.fold<int>(0, (sum, l) => sum + l.$2);
    final buf = StringBuffer('[timing] $title — ${total}ms total\n');
    for (final (label, ms) in _laps) {
      buf.writeln('  ${label.padRight(24, '.')} ${ms}ms');
    }
    debugPrint(buf.toString().trimRight());
  }
}

final budgetClassProvider =
    StateProvider<BudgetClass>((ref) => BudgetClass.flexible);

/// Thrown by [aiRecommendedVendorsProvider] when the couple hasn't entered a
/// wedding budget yet. The AI must never pick or rank a vendor without a real
/// budget to weigh price against — surfacing this as a distinct error (rather
/// than silently matching on price-blind scores) lets the UI ask the couple
/// to enter their budget instead of showing recommendations that were never
/// actually checked against what they intend to spend.
class NoBudgetSetException implements Exception {
  const NoBudgetSetException();
}

/// Location entered by the couple in wizard Step 0 — takes priority over profile location.
final wizardLocationProvider = StateProvider<String?>((ref) => null);

/// Budget entered by the couple in wizard Step 0 — takes priority over the
/// saved [Budget]/profile total. Both of those are only updated by
/// fire-and-forget network calls (`_saveProfile`/`budgetProvider.loadBudget`),
/// so reading them directly here would validate against whatever stale total
/// happened to be persisted from a previous session while those calls are
/// still in flight, rather than the amount the couple just typed.
final wizardBudgetProvider = StateProvider<double?>((ref) => null);

/// Guest count entered by the couple in wizard Step 0 — takes priority over
/// the saved profile's guestCount, same rationale as [wizardBudgetProvider]:
/// the profile save is a fire-and-forget call that may still be in flight.
final wizardGuestCountProvider = StateProvider<int?>((ref) => null);

/// Style preferences chosen by the couple in wizard Step 2 — feeds the AI vendor matcher.
final wizardStylesProvider = StateProvider<List<String>>((ref) => const []);

/// AI-authored reasoning for the current top picks, keyed by category —
/// starts empty and is filled in the background by [_backfillAiExplanations]
/// well after [aiRecommendedVendorsProvider] has already returned its
/// deterministic picks to the couple. The vendor-match cards in
/// couple_planning_screen.dart merge an entry in here over the matching
/// [VendorMatch]'s own deterministic reasoning once it arrives (see
/// `_applyAiExplanation`) — a slow or failed AI call simply means a card
/// keeps the reasoning it already shipped with, never a blocked result.
final vendorMatchExplanationsProvider =
    StateProvider<Map<String, VendorMatchSuggestion>>((ref) => const {});

/// Gathers the couple's real budget/location/category context and runs the
/// pre-AI validation pipeline: hard-stops when there's no real vendor data to
/// build any plan from at all — nobody in the location, or the entered
/// budget can't afford even the single cheapest real vendor on file — and
/// otherwise spends the budget down sequentially, category by category in
/// the order requested, funding each from whatever's left until the money
/// runs out (see Step 6 below). A non-null [VendorValidationResult.blockingFailure]
/// means the vendor-matching AI must never run — [aiRecommendedVendorsProvider]
/// gates on this result before calling it.
final vendorMatchValidationProvider =
    FutureProvider<VendorValidationResult>((ref) async {
  final timer = _StageTimer();
  final budgetClass = ref.watch(budgetClassProvider);
  final categories = ref.watch(selectedServiceCategoriesProvider);
  final coupleProfile = ref.watch(coupleProfileProvider);
  final wizardLocation = ref.watch(wizardLocationProvider);
  final wizardBudget = ref.watch(wizardBudgetProvider);
  final wizardGuestCount = ref.watch(wizardGuestCountProvider);
  final savedBudget = ref.watch(budgetProvider).data;

  final enteredBudget = (wizardBudget != null && wizardBudget > 0)
      ? wizardBudget
      : savedBudget?.totalAmount ?? coupleProfile?.totalBudget;
  if (enteredBudget == null || enteredBudget <= 0) {
    throw const NoBudgetSetException();
  }

  final locationString = (wizardLocation != null && wizardLocation.isNotEmpty)
      ? wizardLocation
      : coupleProfile?.location;
  // A fresh guest count typed into the wizard right now always wins (the
  // couple is actively telling this run what to use); otherwise prefer the
  // real confirmed RSVP total over the stale onboarding estimate once any
  // RSVPs exist — see effectiveGuestCountProvider.
  final guestCount = (wizardGuestCount != null && wizardGuestCount > 0)
      ? wizardGuestCount
      : ref.watch(effectiveGuestCountProvider);
  timer.lap('Input validation');

  // Fetches only the couple's requested categories, filtered at the DB query
  // level (see routes/vendors.js's category_in) — not [allVendorsProvider],
  // which pages through *every* vendor in *every* category. That full-table
  // fetch is what made matching visibly slower as the vendor pool grew: a
  // couple who picked 5 categories was still paying for every page of every
  // other category too, only to discard them a moment later in
  // VendorFilteringService.filterEligible. Scoping the fetch itself keeps
  // both the DB scan and the network payload proportional to what this
  // couple actually asked for. Routed through [vendorPoolProvider] (rather
  // than calling VendorApiService directly) so this stage stays overridable
  // in tests — see that provider's doc comment.
  final fetchedVendors = await ref.watch(vendorPoolProvider(categories).future);
  timer.lap('Database fetch (${fetchedVendors.length} vendors)');

  // Step 0 — subtract what the couple has already decided.
  //
  // A vendor with a live request is a commitment, not a candidate: re-running
  // the plan must never re-propose them, nor quietly swap them for someone
  // else in the same category. So the category is locked out of matching
  // entirely and its vendor removed from the pool, and only the categories
  // still genuinely undecided go on to be scored. A declined or cancelled
  // request is finished business and frees its category again — see
  // [InquiryStatusDisplay.isActive].
  //
  // A locked vendor that isn't in this pool (its category isn't among the ones
  // the couple selected this time) is still dropped from the pool, but locks
  // no category — there's nothing here to lock.
  final activeRequests = await ref.watch(activeRequestsByVendorProvider.future);
  final lockedCategories = <String, LockedCategoryRequest>{};
  if (activeRequests.isNotEmpty) {
    for (final vendor in fetchedVendors) {
      final inquiry = activeRequests[vendor.id];
      if (inquiry == null) continue;
      lockedCategories.putIfAbsent(
        vendor.category,
        () => LockedCategoryRequest(vendor: vendor, inquiry: inquiry),
      );
    }
  }
  final allVendors = activeRequests.isEmpty
      ? fetchedVendors
      : fetchedVendors.where((v) => !activeRequests.containsKey(v.id)).toList();
  final openCategories =
      categories.where((c) => !lockedCategories.containsKey(c)).toList();

  // Money already spoken for by those requests must leave the budget before
  // anything else is funded against it, or the remaining categories would be
  // allocated money the couple has effectively already committed and the
  // budget recap would overstate what's left.
  final lockedSpend = lockedCategories.values
      .map((l) => l.vendor.priceForClass(budgetClass))
      .where((p) => p > 0)
      .fold<double>(0, (sum, p) => sum + p);
  final budgetForOpenCategories = enteredBudget - lockedSpend;

  // Every requested category is already committed — there is nothing left to
  // match, and that's a success state, not a failure.
  if (openCategories.isEmpty) {
    timer.report('Vendor validation pipeline (all categories already requested)');
    return VendorValidationResult(lockedCategories: lockedCategories);
  }

  // Step 1 — filter by category, then hard-restrict to the couple's location.
  final eligible = VendorFilteringService.filterEligible(allVendors, openCategories);
  final locationPool = VendorFilteringService.restrictToLocation(eligible.pool, locationString);
  timer.lap('Category + location filtering');

  // Step 2 — a location with literally nobody in it, across every requested
  // category, is a whole-plan stop: there's nothing real to build a plan from.
  final locationFailure = LocationValidationService.validate(
    locationFilteredPool: locationPool,
    location: locationString,
  );
  if (locationFailure != null) {
    timer.report('Vendor validation pipeline (blocked: no vendors in location)');
    return VendorValidationResult(
      lockedCategories: lockedCategories,
      blockingFailure: locationFailure,
    );
  }

  final byCategory = VendorFilteringService.groupByCategory(locationPool, openCategories);

  // Step 3 — per-category coverage. A category with zero vendors is excluded
  // (soft, single-category message) rather than blocking the whole plan, so
  // the couple can still add their own vendor for just that gap.
  final coverage = BudgetValidationService.validateCoverage(
    byCategory: byCategory,
    location: locationString,
  );

  // Step 3b — per-category guest-capacity coverage. Runs before budget
  // funding so a caterer too small for the party is invisible to it from
  // the start — see GuestCapacityValidationService for why this stays a
  // separate, price-blind stage rather than folding into budget messaging.
  final capacityChecked = GuestCapacityValidationService.validate(
    byCategory: coverage.covered,
    guestCount: guestCount,
  );
  timer.lap('Coverage + guest-capacity filtering');

  // Step 3c — whole-plan stop: every category that had real vendors in the
  // couple's location lost every single one of them to the capacity check
  // above, so there's nothing left anywhere to build a plan from. Distinct
  // from Step 2's location check (there were vendors here, just none big
  // enough) and never raised when coverage.covered was already empty for
  // location reasons — that's Step 2's failure to report, not this one's.
  if (coverage.covered.isNotEmpty && capacityChecked.covered.isEmpty) {
    timer.report('Vendor validation pipeline (blocked: no vendor meets guest capacity)');
    return VendorValidationResult(
      lockedCategories: lockedCategories,
      blockingFailure: VendorValidationFailure(
        type: VendorValidationFailureType.noVendorCapacityForGuestCount,
        message:
            'No vendors are currently available that can serve your wedding size of '
            '$guestCount guests. Please reduce the number of guests or choose another vendor.',
      ),
    );
  }

  final weddingDateStr = coupleProfile?.weddingDate != null
      ? coupleProfile!.weddingDate!.toIso8601String().split('T').first
      : null;

  // Step 4 — prefer the couple's wedding-class rating band within each
  // category (High class → 4.5★+, Budget-friendly → under 4.5★ or unrated,
  // Flexible → either), falling back to the full category when nobody
  // matches so a class preference never empties out a category.
  final weddingClassFiltered =
      VendorFilteringService.preferredByWeddingClass(capacityChecked.covered, budgetClass);

  // Step 4b — hard-exclude vendors already booked on the couple's wedding
  // date, per category, before budget is ever funded against one of them —
  // see VendorFilteringService.excludeBookedOnDate for the graceful-degrade
  // fallback when a category would otherwise go to zero.
  final ratedByCategory =
      VendorFilteringService.excludeBookedOnDate(weddingClassFiltered, weddingDateStr);
  timer.lap('Wedding-class + availability filtering');

  // Every affordability figure below uses the class-adjusted price: High
  // Class budgets against the premium end of each vendor (their luxury
  // package price, else the top of their range) so the numbers reflect what
  // luxury actually costs, while the other classes budget from the minimum.
  double priceOf(VendorProfile v) => v.priceForClass(budgetClass);

  // Step 5 — reject the whole plan outright when the entered budget can't
  // afford even the single cheapest real vendor available anywhere across
  // the couple's requested categories/location. There's no honest plan to
  // build from real data at that amount, so the AI must never run at all.
  final pricedPool = [for (final vendors in ratedByCategory.values) ...vendors]
      .where((v) => priceOf(v) > 0);
  if (pricedPool.isNotEmpty) {
    final cheapestOverall =
        pricedPool.map(priceOf).reduce((a, b) => a < b ? a : b);
    // Measured against what's left after already-requested vendors, not the
    // headline budget — money committed to a live request can't fund anything
    // else.
    if (cheapestOverall - budgetForOpenCategories > _kBudgetEpsilon) {
      timer.report('Vendor validation pipeline (blocked: budget too low)');
      return VendorValidationResult(
        lockedCategories: lockedCategories,
        blockingFailure: VendorValidationFailure(
          type: VendorValidationFailureType.budgetTooLowForAnyVendor,
          message: lockedSpend > 0
              ? 'After the ${fmtCurrency(lockedSpend)} committed to vendors you\'ve already '
                  'requested, the ${fmtCurrency(budgetForOpenCategories)} left is too small for any '
                  'vendor we have on file — the cheapest available costs ${fmtCurrency(cheapestOverall)}. '
                  'Please increase your budget or cancel a request to continue.'
              : 'Your budget of ${fmtCurrency(enteredBudget)} is too small for any vendor we '
                  'have on file — the cheapest available vendor costs ${fmtCurrency(cheapestOverall)}. '
                  'Please increase your budget to continue.',
        ),
      );
    }
  }

  // Step 6 — fund each category at its own real price, sequentially in the
  // order requested, then use two follow-up passes so the total spend is
  // honest to what real vendors actually cost instead of an artificial even
  // split:
  //   1. Sequential real-price funding — a category is funded the moment its
  //      cheapest real vendor fits what's genuinely left (never a pre-divided
  //      fraction of it). The ceiling handed downstream is exactly what the
  //      winning pick costs, so every category's ceiling is a real, tight
  //      number and ceilings can never sum to more than the entered budget.
  //   2. Rescue pass — if a category can't be funded, look for the single
  //      biggest saving available by dropping an already-funded category
  //      down to its own cheapest real vendor, and keep doing that until
  //      either enough is freed to fund the stuck category for real, or
  //      every funded category is already at its floor (nothing left to
  //      swap). If the rescue doesn't work out, every downgrade tried purely
  //      for it is undone — there's no reason to hand the couple a worse
  //      pick for a rescue that didn't pay off.
  //   3. Polish pass — once nothing is stuck, spend whatever's left over on
  //      upgrading categories to the next real, pricier vendor in the same
  //      category as long as it still fits, so the total lands as close to
  //      the entered budget as the real vendor pool allows instead of
  //      quietly under-spending.
  final coords = locationString != null ? coordsForLocation(locationString) : null;

  final fundableCategories = openCategories
      .where((c) =>
          !coverage.excludedMessages.containsKey(c) &&
          !capacityChecked.excludedMessages.containsKey(c))
      .toList();

  // The cheapest real, priced vendor on file in each category — the floor
  // both the initial funding check and every later rescue/downgrade measure
  // against. A category with nothing but unpriced vendors has no floor and
  // is never blocked on affordability.
  final cheapestPriceByCategory = <String, double>{};
  for (final cat in fundableCategories) {
    final priced =
        (ratedByCategory[cat] ?? const <VendorProfile>[]).map(priceOf).where((p) => p > 0);
    if (priced.isNotEmpty) {
      cheapestPriceByCategory[cat] = priced.reduce((a, b) => a < b ? a : b);
    }
  }

  // The top-scored real price a category would settle on if it could spend
  // up to [ceiling] — used only to decide *which* vendor wins a category's
  // funding round. The ceiling actually exposed downstream is set by the
  // caller from whatever this returns, never from [ceiling] itself, so it
  // always stays a tight, real number.
  double? scoredPickPrice(String cat, double ceiling) {
    final candidates = ratedByCategory[cat] ?? const <VendorProfile>[];
    final affordable = candidates
        .where((v) => priceOf(v) <= 0 || priceOf(v) - ceiling <= _kBudgetEpsilon)
        .toList();
    final scored = _AiEngine.scoreAll(affordable, budgetClass, coords?[0], coords?[1],
        weddingDateStr, {cat: ceiling}, eligible.tiers, guestCount);
    if (scored.isEmpty) return null;
    return scored.reduce((a, b) => a.finalScore >= b.finalScore ? a : b).effectivePrice;
  }

  var remaining = budgetForOpenCategories;
  final ceilings = <String, double>{};
  final committedPrice = <String, double>{};
  final exhaustedMessages = <String, String>{};
  final deferred = <String>[];

  // Phase 1 — sequential real-price funding. A category whose cheapest real
  // vendor doesn't currently fit is *deferred*, not treated as fatal for
  // everyone after it — every other fundable category still gets its normal
  // shot in Phase 1, regardless of where the expensive one sits in the
  // requested order. This used to short-circuit: the moment one category
  // ran out of room, every category after it in iteration order was marked
  // "money ends here" without ever being tested against what was actually
  // left — including categories that, funded on their own, would have fit
  // easily. A couple re-entering their own "budget used" total from a
  // previous run (less slack, same real prices) was the common way to hit
  // this: a different category happened to go first, ate the budget
  // differently, and everything after it got blamed for a shortfall that
  // was really just funding-order sensitivity.
  for (final cat in fundableCategories) {
    final cheapest = cheapestPriceByCategory[cat];
    if (cheapest != null && cheapest - remaining > _kBudgetEpsilon) {
      deferred.add(cat);
      continue;
    }

    final price = scoredPickPrice(cat, remaining) ?? 0;
    committedPrice[cat] = price;
    ceilings[cat] = price; // tight — never more than what was actually picked
    if (price > 0) remaining -= price;
  }

  // Phase 2 — rescue pass, cheapest-shortfall first. Every category deferred
  // above gets a real attempt: downgrade already-funded categories to their
  // own cheapest floor (biggest saving first) until either this one fits or
  // there is nothing left to downgrade. Processing cheapest-first means a
  // category that only needed a small saving isn't starved by downgrades
  // spent rescuing a pricier one ahead of it in the list.
  final byShortfall = List<String>.from(deferred)
    ..sort((a, b) => cheapestPriceByCategory[a]!
        .compareTo(cheapestPriceByCategory[b]!));

  for (final cat in byShortfall) {
    final cheapestE = cheapestPriceByCategory[cat]!;
    if (cheapestE - remaining <= _kBudgetEpsilon) {
      // A downgrade made while rescuing an earlier category already freed
      // enough — no fresh downgrade needed for this one.
      ceilings[cat] = cheapestE;
      committedPrice[cat] = cheapestE;
      remaining -= cheapestE;
      deferred.remove(cat);
      continue;
    }

    final ceilingsSnapshot = Map<String, double>.from(ceilings);
    final committedSnapshot = Map<String, double>.from(committedPrice);
    final remainingSnapshot = remaining;
    final downgraded = <String>{};

    while (cheapestE - remaining > _kBudgetEpsilon) {
      String? bestCat;
      var bestSaving = 0.0;
      for (final funded in ceilings.keys) {
        if (downgraded.contains(funded)) continue;
        final floor = cheapestPriceByCategory[funded];
        if (floor == null) continue;
        final saving = committedPrice[funded]! - floor;
        if (saving > bestSaving) {
          bestSaving = saving;
          bestCat = funded;
        }
      }
      if (bestCat == null) break;

      final floor = cheapestPriceByCategory[bestCat]!;
      remaining += committedPrice[bestCat]! - floor;
      committedPrice[bestCat] = floor;
      ceilings[bestCat] = floor;
      downgraded.add(bestCat);
    }

    if (cheapestE - remaining <= _kBudgetEpsilon) {
      ceilings[cat] = cheapestE;
      committedPrice[cat] = cheapestE;
      remaining -= cheapestE;
      deferred.remove(cat);
    } else {
      // Rescue didn't work out for this one — undo every downgrade tried
      // for it and leave it deferred; later, cheaper-shortfall categories in
      // this same pass already succeeded and stay funded.
      ceilings
        ..clear()
        ..addAll(ceilingsSnapshot);
      committedPrice
        ..clear()
        ..addAll(committedSnapshot);
      remaining = remainingSnapshot;
    }
  }

  // Whatever is still deferred after every rescue attempt is genuinely
  // unaffordable given what every other category actually needed — the
  // message is only ever shown once that's actually true.
  for (final cat in deferred) {
    final cheapest = cheapestPriceByCategory[cat]!;
    exhaustedMessages[cat] = 'Cannot proceed — your money ends here. Even the cheapest real '
        '$cat vendor costs ${fmtCurrency(cheapest)}, more than the ${fmtCurrency(remaining)} '
        'you have left. Add more to your budget to continue matching.';
  }

  // Phase 3 — polish pass: spend whatever's left on real, pricier upgrades
  // within categories already funded, so the total lands close to the
  // entered budget rather than quietly under-spending it.
  if (remaining > _kBudgetEpsilon) {
    var changed = true;
    while (changed) {
      changed = false;
      for (final cat in ceilings.keys.toList()) {
        final current = committedPrice[cat] ?? 0;
        final above = (ratedByCategory[cat] ?? const <VendorProfile>[])
            .map(priceOf)
            .where((p) => p > current)
            .toList();
        if (above.isEmpty) continue;
        final nextPrice = above.reduce((a, b) => a < b ? a : b);
        final delta = nextPrice - current;
        if (delta - remaining <= _kBudgetEpsilon) {
          remaining -= delta;
          committedPrice[cat] = nextPrice;
          ceilings[cat] = nextPrice;
          changed = true;
        }
      }
    }
  }

  final fundedByCategory = <String, List<VendorProfile>>{
    for (final cat in ceilings.keys)
      cat: (ratedByCategory[cat] ?? const <VendorProfile>[])
          .where((v) => priceOf(v) <= 0 || priceOf(v) - ceilings[cat]! <= _kBudgetEpsilon)
          .toList(),
  };
  timer.lap('Budget funding (sequential + rescue + polish)');
  timer.report('Vendor validation pipeline');

  return VendorValidationResult(
    byCategory: fundedByCategory,
    tiers: eligible.tiers,
    categoryBudgets: ceilings,
    excludedCategoryMessages: coverage.excludedMessages,
    budgetExhaustedMessages: exhaustedMessages,
    guestCapacityExcludedMessages: capacityChecked.excludedMessages,
    lockedCategories: lockedCategories,
  );
});

final aiRecommendedVendorsProvider =
    FutureProvider<List<VendorMatch>>((ref) async {
  final timer = _StageTimer();
  final budgetClass = ref.watch(budgetClassProvider);
  final coupleProfile = ref.watch(coupleProfileProvider);
  final wizardLocation = ref.watch(wizardLocationProvider);
  final wizardStyles = ref.watch(wizardStylesProvider);
  final wizardGuestCount = ref.watch(wizardGuestCountProvider);
  final guestCount = (wizardGuestCount != null && wizardGuestCount > 0)
      ? wizardGuestCount
      : ref.watch(effectiveGuestCountProvider);

  final validation = await ref.watch(vendorMatchValidationProvider.future);
  timer.lap('Validation pipeline (breakdown logged separately above)');
  if (validation.isBlocked) {
    throw VendorValidationException(validation.blockingFailure!);
  }

  final locationString = (wizardLocation != null && wizardLocation.isNotEmpty)
      ? wizardLocation
      : coupleProfile?.location;
  final coords =
      locationString != null ? coordsForLocation(locationString) : null;
  final weddingDateStr = coupleProfile?.weddingDate != null
      ? coupleProfile!.weddingDate!.toIso8601String().split('T').first
      : null;

  final pool = [for (final vendors in validation.byCategory.values) ...vendors];
  final categoryBudgets = validation.categoryBudgets;
  final tiers = validation.tiers;

  final scored = _AiEngine.scoreAll(pool, budgetClass, coords?[0], coords?[1],
      weddingDateStr, categoryBudgets, tiers, guestCount);
  // This deterministic ranking is now the sole decision-maker for which
  // vendor wins each category — see `_AiEngine._finalScore`. It's already
  // scored against the exact same per-category ledger the sequential
  // funding pass used to decide how much each category could spend, so its
  // picks can never sum past what the couple entered; no AI-divergence
  // safety net is needed the way one was when the AI could still pick.
  final matches = _AiEngine.recommend(
      pool: pool,
      scored: scored,
      budgetClass: budgetClass,
      styles: wizardStyles);
  timer.lap('Local scoring + ranking (${scored.length} vendors)');

  // Neither the local ranking nor the LLM ever refuses to name a "best" pick
  // — but a pick that's merely the closest available option isn't the same
  // thing as a pick that actually fits. Re-check every category's top pick
  // against what's actually affordable and correct the record: flag it when
  // literally nothing in the category fits the allocated amount (the budget
  // itself is unrealistic, not just this pick), and force the pick to the
  // sole affordable vendor when exactly one exists, so the couple is never
  // shown a "top match" that quietly lost to a cheaper option that fit.
  final realisticMatches = _AiEngine.enforceBudgetRealism(
      matches, scored, budgetClass, categoryBudgets, wizardStyles);

  // The couple should never see a "budget allocation" that's some computed
  // split they can't trace to anything real — once a category's winner is
  // decided, its allocation IS exactly what that vendor charges, full stop.
  final finalMatches = _AiEngine.realizeCategoryAllocations(
      realisticMatches, scored, budgetClass, wizardStyles);

  // Only ever one card per category, in every budget class — no "Alternative
  // #2/#3" comparison. `finalMatches` is a FULL per-category ranking, so
  // this is the one place that guarantees only rankInCategory == 1 ever
  // reaches the couple.
  final topPicksOnly =
      finalMatches.where((m) => m.rankInCategory == 1).toList();
  timer.lap('Post-processing (budget/realism/allocation passes)');
  timer.report('Vendor matches (${topPicksOnly.length} picks — AI reasoning loads in background)');

  // Both calls below are fire-and-forget: the couple already has their
  // matches by the time either one resolves, and neither is allowed to add
  // a network round-trip to the critical path. _syncTopMatches is a
  // best-effort backend sync (see its own doc comment). The explanation
  // backfill asks the AI to write human-readable justification for the
  // picks already decided above — a slow or failed response just means a
  // card keeps the deterministic reasoning it already shipped with.
  unawaited(_syncTopMatches(ref, topPicksOnly));
  unawaited(_backfillAiExplanations(
      ref, topPicksOnly, scored, budgetClass, locationString, wizardStyles, categoryBudgets));
  return topPicksOnly;
});

/// Background-only: asks the AI to write reasoning for the categories whose
/// top pick actually changed since the last successful explanation (skips
/// the rest — no reason to spend a call on the shared, rate-limited free-tier
/// key re-explaining a vendor it already wrote about). Never awaited by
/// [aiRecommendedVendorsProvider] — see that provider's return statement.
Future<void> _backfillAiExplanations(
  Ref ref,
  List<VendorMatch> topPicksOnly,
  List<_ScoredVendor> scored,
  BudgetClass budgetClass,
  String? locationString,
  List<String> wizardStyles,
  Map<String, double> categoryBudgets,
) async {
  final alreadyExplained = ref.read(vendorMatchExplanationsProvider);
  final scoredByVendorId = {for (final s in scored) s.vendor.id: s};

  final picks = <String, VendorMatchCandidate>{};
  for (final m in topPicksOnly) {
    if (alreadyExplained[m.vendor.category]?.vendorId == m.vendorId) continue;
    final s = scoredByVendorId[m.vendorId];
    if (s == null) continue;
    picks[m.vendor.category] = VendorMatchCandidate(
      vendorId: s.vendor.id,
      businessName: s.vendor.businessName,
      location: s.vendor.location,
      styleTags: s.vendor.styleTags,
      rating: s.vendor.rating,
      feedbackCount: s.vendor.feedbackCount,
      priceTier: s.priceTier.name,
      priceMin: s.effectivePrice,
      priceMax: s.vendor.priceMax > s.effectivePrice ? s.vendor.priceMax : s.effectivePrice,
      reputationScore: s.reputation,
      locationScore: s.location,
      valueScore: s.value,
      isBookedOnWeddingDate: s.isBookedOnWeddingDate,
    );
  }
  if (picks.isEmpty) return;

  // /api/vendor-match is authenticated now. Without a session there is
  // nothing to send, and the deterministic reasoning the engine already
  // produced stays on screen — same outcome as the AI call failing.
  final accessToken = ref.read(authProvider.notifier).accessToken;
  if (accessToken == null) return;

  final sw = Stopwatch()..start();
  try {
    final suggestions = await WeddingAiService.instance.explainVendorMatches(
      budgetClass: budgetClass.name,
      location: locationString,
      styles: wizardStyles,
      picks: picks,
      categoryBudgets: categoryBudgets,
      accessToken: accessToken,
    );
    ref.read(vendorMatchExplanationsProvider.notifier).state = {
      ...ref.read(vendorMatchExplanationsProvider),
      ...suggestions,
    };
    if (kDebugMode) {
      debugPrint(
          '[timing] AI explanation backfill (${picks.length}/${topPicksOnly.length} categories) — ${sw.elapsedMilliseconds}ms');
    }
  } catch (_) {
    // Best-effort — cards keep the deterministic reasoning they already have.
  }
}

/// Reports the current top pick per category to the backend, which persists
/// it and notifies the couple only when a pick is new or has changed since
/// last time — this never fires on its own, only relaying a real computation.
Future<void> _syncTopMatches(Ref ref, List<VendorMatch> matches) async {
  final token = ref.read(authProvider.notifier).accessToken;
  if (token == null) return;
  // Curated (frontend-only, id prefixed 'curated-') picks have no backend
  // row to sync against — skip them rather than writing a VendorMatch that
  // can never resolve to a real vendor.
  final topPicks = matches
      .where((m) => m.rankInCategory == 1 && !m.vendorId.startsWith('curated-'))
      .toList();
  if (topPicks.isEmpty) return;
  try {
    await CoupleProfileService.instance.syncVendorMatches(
      token,
      topPicks
          .map((m) => {
                'category': m.vendor.category,
                'vendor_id': m.vendorId,
                'confidence': m.finalScore,
              })
          .toList(),
    );
  } catch (_) {
    // Best-effort — a failed sync shouldn't block showing the couple their matches.
  }
}

// ── AI Recommendation Engine ────────────────────────────────────────────────
//
// `scoreAll` computes the grounding signals sent to the real LLM matcher (see
// `WeddingAiService.matchVendors`), using the category/location filtering
// already done by `VendorFilteringService` as part of the pre-AI validation
// pipeline. `recommend` composes them into a fully ranked local result and
// serves as the offline fallback when the LLM call fails or returns
// something malformed.

class _AiEngine {
  _AiEngine._();

  static List<_ScoredVendor> scoreAll(
    List<VendorProfile> pool,
    BudgetClass budgetClass,
    double? coupleLat,
    double? coupleLon,
    String? weddingDateStr,
    Map<String, double> categoryBudgets,
    Map<String, VendorPriceTier> priceTiers, [
    int? guestCount,
  ]) {
    return pool.map((v) {
      final tier = priceTiers[v.id] ?? v.priceTier;
      final rep = v.performanceScore;
      final loc = _locationScore(v, coupleLat, coupleLon);
      final categoryBudget = categoryBudgets[v.category];
      final price = v.priceForClass(budgetClass);
      final val = _valueScore(price, budgetClass, categoryBudget);
      final isBooked =
          weddingDateStr != null && v.blockedDates.contains(weddingDateStr);
      // A price within a cent of the category's budget counts as fitting
      // exactly, never as "slightly over" — see _kBudgetEpsilon.
      final overBudgetRatio = categoryBudget != null &&
              categoryBudget > 0 &&
              (price - categoryBudget) > _kBudgetEpsilon
          ? ((price - categoryBudget) / categoryBudget).clamp(0.0, 1.0)
          : 0.0;
      final fin =
          _finalScore(rep, loc, val, budgetClass, isBooked, overBudgetRatio);
      return _ScoredVendor(
        vendor: v,
        reputation: rep,
        location: loc,
        value: val,
        finalScore: fin,
        isBookedOnWeddingDate: isBooked,
        categoryBudget: categoryBudget,
        overBudgetRatio: overBudgetRatio,
        priceTier: tier,
        effectivePrice: price,
        capacityRank: _capacityRank(v, guestCount),
        guestCount: guestCount,
      );
    }).toList();
  }

  /// Ranks a vendor by closeness to the couple's guest count — the dominant
  /// primary sort key in [recommend], ahead of budget/location/rating. `0`
  /// when there's no guest count to compare against (capacity never affects
  /// ranking without one); the sentinel `1 << 30` when no listing states a
  /// capacity that covers the headcount (weakest signal, same "unstated =
  /// neutral, not a rejection" rule as [VendorProfile.canServeGuestCount] —
  /// never excluded, just ranked behind every vendor who proved a real fit);
  /// otherwise `capacity - guestCount`, so `0` is an exact match and smaller
  /// positive values are closer above it.
  ///
  /// Measured against [VendorProfile.fittingGuestCapacity] rather than
  /// [VendorProfile.maxGuestCapacity], which would be wrong in both
  /// directions: a vendor listing both a 100- and a 500-guest package would
  /// rank 400 seats oversized for a 100-guest wedding instead of as the exact
  /// match it is, and a vendor whose only qualifying listing states *no*
  /// capacity (the neutral case that let them past
  /// [GuestCapacityValidationService]) would rank on a smaller listing that
  /// can't seat the party at all — going negative, which sorts ahead of every
  /// genuine exact match. This value is never negative.
  static int _capacityRank(VendorProfile v, int? guestCount) {
    if (guestCount == null || guestCount <= 0) return 0;
    final capacity = v.fittingGuestCapacity(guestCount);
    if (capacity == null) return 1 << 30;
    return capacity - guestCount;
  }

  /// Local, deterministic ranking — cannot throw, and is now the sole
  /// decision-maker for which vendor wins each category (see
  /// `aiRecommendedVendorsProvider`). The AI is never asked to choose
  /// between candidates anymore, only to explain a pick already made here —
  /// see `_backfillAiExplanations`, which builds a single [VendorMatchCandidate]
  /// per category directly from this ranking's winner.
  static List<VendorMatch> recommend({
    required List<VendorProfile> pool,
    required List<_ScoredVendor> scored,
    required BudgetClass budgetClass,
    List<String> styles = const [],
  }) {
    // Priority ladder, each level only breaking ties left by the one above:
    // 1-2. Capacity closeness (exact match, then closest-higher) — see
    //      [_capacityRank]. Dominant across every wedding class; a smaller
    //      vendor never outranks a closer-fitting one just for scoring
    //      higher on reputation/value/location.
    // 3.   Budget compatibility — least over-budget wins; both-fit ties break
    //      on value score (how well-priced within the allocation).
    // 4.   Location compatibility.
    // 5.   Vendor rating (reputation).
    // `finalScore` stays computed on every [_ScoredVendor] (still used
    // elsewhere as a confidence figure, e.g. `_syncTopMatches`), it just no
    // longer drives this order directly.
    final ranked = [...scored]..sort((a, b) {
      final capacity = a.capacityRank.compareTo(b.capacityRank);
      if (capacity != 0) return capacity;
      final budget = a.overBudgetRatio.compareTo(b.overBudgetRatio);
      if (budget != 0) return budget;
      if (a.overBudgetRatio <= 0 && b.overBudgetRatio <= 0) {
        final value = b.value.compareTo(a.value);
        if (value != 0) return value;
      }
      final location = b.location.compareTo(a.location);
      if (location != 0) return location;
      return b.reputation.compareTo(a.reputation);
    });

    final catTotal = <String, int>{};
    for (final s in ranked) {
      catTotal[s.vendor.category] = (catTotal[s.vendor.category] ?? 0) + 1;
    }
    final catRank = <String, int>{};

    return ranked.map((s) {
      final rank = (catRank[s.vendor.category] ?? 0) + 1;
      catRank[s.vendor.category] = rank;
      return _buildMatch(s, budgetClass, rank, catTotal[s.vendor.category]!, styles);
    }).toList();
  }

  static VendorMatch _buildMatch(
    _ScoredVendor s,
    BudgetClass budgetClass,
    int rank,
    int total,
    List<String> styles,
  ) {
    final steps = _reasonSteps(s.vendor, budgetClass, rank, s.isBookedOnWeddingDate,
        s.categoryBudget, s.overBudgetRatio, styles, s.location, s.effectivePrice,
        s.guestCount);

    // Mirrors the backend's budget-fit/fallback rules (see /api/vendor-match):
    // a category with no allocated budget, or a pick priced at or under it,
    // counts as an exact match; eligibility filtering has already restricted
    // this class's pool to its matching price tier, so anything left over
    // budget is by construction the class's best remaining tier fit.
    final fitsBudget = s.categoryBudget == null || s.overBudgetRatio <= 0;
    final budgetDeltaPercent = (!fitsBudget && s.categoryBudget != null && s.categoryBudget! > 0)
        ? (((s.effectivePrice - s.categoryBudget!) / s.categoryBudget!) * 100).round().toDouble()
        : null;
    final noteToCouple = fitsBudget
        ? 'You have been allocated ${s.effectivePrice > 0 ? '~${s.effectivePrice.toStringAsFixed(0)} ' : ''}for ${s.vendor.category}.'
        : 'No ${budgetClass.displayName.toLowerCase()} pick fit your budget for ${s.vendor.category} '
            'exactly, so this is the closest match for that tier'
            '${budgetDeltaPercent != null ? ' — about ${budgetDeltaPercent.toStringAsFixed(0)}% over what you were allocated' : ''}.';

    return VendorMatch(
      vendorId: s.vendor.id,
      vendor: s.vendor,
      finalScore: s.finalScore,
      reputationScore: s.reputation,
      budgetScore: s.value,
      locationScore: s.location,
      availabilityScore: s.isBookedOnWeddingDate ? 0.0 : 1.0,
      reasoning: steps.map((r) => '${r.label}: ${r.text}').join(' '),
      reasoningSteps: steps,
      rankInCategory: rank,
      totalInCategory: total,
      fitsBudget: fitsBudget,
      budgetDeltaPercent: budgetDeltaPercent,
      selectionBasis:
          fitsBudget ? SelectionBasis.exactBudgetMatch : SelectionBasis.weddingClassBestFit,
      noteToCouple: noteToCouple,
    );
  }

  /// Re-grounds every category's top pick in what's actually affordable.
  /// [matches] only ever hands back "the best of what's there" among the
  /// pool it was scored from, so this is the one place that checks whether
  /// "what's there" was ever realistic for the money entered.
  ///
  /// Only [rankInCategory] == 1 is ever read by the UI (see
  /// [couple_planning_screen.dart]'s `bestByCategory`), so lower ranks are
  /// left untouched — the only correction needed is making sure category's
  /// #1 is the right vendor and carries the right message.
  static List<VendorMatch> enforceBudgetRealism(
    List<VendorMatch> matches,
    List<_ScoredVendor> scored,
    BudgetClass budgetClass,
    Map<String, double> categoryBudgets,
    List<String> styles,
  ) {
    final byCategory = <String, List<_ScoredVendor>>{};
    for (final s in scored) {
      byCategory.putIfAbsent(s.vendor.category, () => []).add(s);
    }

    final result = [...matches];

    for (final entry in byCategory.entries) {
      final cat = entry.key;
      final categoryBudget = categoryBudgets[cat];
      if (categoryBudget == null || categoryBudget <= 0) continue;

      final catScored = entry.value;
      final affordable = catScored
          .where((s) =>
              s.effectivePrice > 0 &&
              s.effectivePrice - categoryBudget <= _kBudgetEpsilon)
          .toList();

      final topIdx = result.indexWhere(
        (m) => m.vendor.category == cat && m.rankInCategory == 1,
      );
      if (topIdx == -1) continue;

      if (affordable.isEmpty) {
        result[topIdx] = result[topIdx].copyWith(
          isBudgetUnrealistic: true,
          fitsBudget: false,
          noteToCouple: 'Your budget for $cat looks unrealistically small — no vendor in '
              '$cat is priced at or under the ~${categoryBudget.toStringAsFixed(0)} you were allocated. '
              'Raise your budget for this category, or trim scope, to get a real match here.',
        );
      } else if (affordable.length == 1) {
        final solo = affordable.first;
        final soleNote =
            'Your budget for $cat only fits one available vendor — ${solo.vendor.businessName}. '
            "We've matched you to them since nothing else in $cat fits what you were allocated.";
        result[topIdx] = result[topIdx].vendorId == solo.vendor.id
            ? result[topIdx].copyWith(
                selectionBasis: SelectionBasis.onlyAffordableOption,
                noteToCouple: soleNote,
              )
            : _buildMatch(solo, budgetClass, 1, catScored.length, styles).copyWith(
                selectionBasis: SelectionBasis.onlyAffordableOption,
                noteToCouple: soleNote,
              );
      }
    }

    return result;
  }

  /// Rewrites every category's #1 pick so its "budget allocation" is exactly
  /// that vendor's own real price — never the sequential ledger figure
  /// (money left when this category was funded) used for ranking. The couple
  /// should never see an allocation figure they can't trace back to an actual
  /// vendor; once the winner is decided, the allocation for that category IS
  /// what they charge, so this always renders as a clean, tautological fit.
  static List<VendorMatch> realizeCategoryAllocations(
    List<VendorMatch> matches,
    List<_ScoredVendor> scored,
    BudgetClass budgetClass,
    List<String> styles,
  ) {
    final scoredByVendorId = {for (final s in scored) s.vendor.id: s};
    final result = [...matches];

    for (var i = 0; i < result.length; i++) {
      final m = result[i];
      if (m.rankInCategory != 1) continue;

      // enforceBudgetRealism already flagged these with a deliberately
      // specific, vendor-grounded alert (no vendor fits at all / only one
      // vendor fits / picked as the closest available fit despite being
      // over budget) — rewriting the allocation here would set
      // overBudgetRatio to 0 and rebuild the match as a plain "You have
      // been allocated ~X" note, silently erasing that warning. Only the
      // ordinary case (genuinely fits, nothing to flag) gets its allocation
      // figure corrected below.
      if (m.isBudgetUnrealistic || m.selectionBasis != SelectionBasis.exactBudgetMatch) {
        continue;
      }

      final s = scoredByVendorId[m.vendorId];
      // A vendor with no real price on file has nothing to realize an
      // allocation from — leave its existing "no allocation set" messaging
      // untouched rather than fabricating a number.
      if (s == null || s.effectivePrice <= 0) continue;

      final realized = _ScoredVendor(
        vendor: s.vendor,
        reputation: s.reputation,
        location: s.location,
        value: s.value,
        finalScore: s.finalScore,
        isBookedOnWeddingDate: s.isBookedOnWeddingDate,
        categoryBudget: s.effectivePrice,
        overBudgetRatio: 0.0,
        priceTier: s.priceTier,
        effectivePrice: s.effectivePrice,
        capacityRank: s.capacityRank,
        guestCount: s.guestCount,
      );
      result[i] = _buildMatch(realized, budgetClass, m.rankInCategory, m.totalInCategory, styles);
    }

    return result;
  }

  static double _locationScore(VendorProfile v, double? lat, double? lon) {
    if (lat == null || lon == null || v.latitude == null || v.longitude == null) {
      return 0.5;
    }
    const maxKm = 300.0;
    final dist = haversineKm(lat, lon, v.latitude!, v.longitude!);
    return (1.0 - dist / maxKm).clamp(0.0, 1.0);
  }

  /// Price fit, scaled against the couple's *actual* allocated budget for
  /// this category rather than where the vendor sits relative to its
  /// siblings — so this genuinely moves as the couple's entered budget
  /// amount moves, not just as the vendor pool happens to be priced.
  /// Reputation is deliberately left out here: [_finalScore] gives it its
  /// own dedicated weight per class, so folding it in again here would
  /// double-count it.
  static double _valueScore(double price, BudgetClass bc, double? categoryBudget) {
    // A vendor with no price on file isn't "cheap" (that has to be earned by
    // an actual low price, or a confirmed-affordable vendor would lose to an
    // unpriced one purely for having no data) nor "expensive" — treat it as
    // sitting exactly on the budget line: neither a proven bargain nor a
    // proven splurge, so it can neither win nor lose a class's dominant
    // signal just for lacking data. [price] is already class-adjusted (see
    // VendorProfile.priceForClass).
    final priceRatio = (categoryBudget != null && categoryBudget > 0 && price > 0)
        ? price / categoryBudget
        : 1.0;
    return switch (bc) {
      // How "premium" this looks relative to what the couple allocated —
      // only a light tiebreaker here since reputation already decides High
      // class almost entirely (see _finalScore).
      BudgetClass.highClass => priceRatio.clamp(0.0, 1.5) / 1.5,
      // Same "cheaper relative to allocation wins" signal as budget-friendly,
      // just weighted much lighter in _finalScore. This has to be a genuine
      // price signal (not quality again) or a top-rated-but-pricier vendor
      // can never lose to a cheaper-but-still-solid one on anything but
      // reputation — the couple's actual money stops being a factor at all,
      // and flexible collapses into "always pick the best reviewed", never
      // able to land on the budget-friendly side the way its "either tier"
      // description promises.
      BudgetClass.flexible => (1.0 - priceRatio).clamp(0.0, 1.0),
      // Cheaper relative to the couple's allocation wins outright; saturates
      // once price reaches the allocation itself — how far over that point
      // a vendor is gets penalized separately via overBudgetRatio.
      BudgetClass.budgetFriendly => (1.0 - priceRatio).clamp(0.0, 1.0),
    };
  }

  // Booked vendors aren't excluded outright, but a confirmed conflict on the
  // couple's date should outweigh most quality/price differences, so they're
  // pushed toward the bottom of their category rather than removed.
  static const double _bookedPenalty = 0.45;

  // Being priced beyond the couple's allocated budget for a category is a
  // graduated penalty (worse the further over they are), not a hard cutoff —
  // an over-budget vendor can still surface as the pick if nothing in that
  // category fits, but it will rank below anything that does fit.
  static const double _overBudgetWeight = 0.40;

  // Each wedding class has one deliberately dominant signal — a couple who
  // picked a class is telling the AI what to optimize for, so that signal
  // should decide the pick, not just nudge a three-way blend:
  //   - High class: reputation. "Premium only" means the best-reviewed
  //     vendor in the category wins, full stop — location/price are minor
  //     tiebreakers, not co-equal factors.
  //   - Flexible: a genuine balanced blend across reputation, price, and
  //     location — every reputation tier stays welcome and no one signal
  //     dominates.
  //   - Budget-friendly: price. The couple explicitly wants to spend less,
  //     so the cheapest-relative-to-their-allocation vendor wins outright,
  //     with reputation only as a light tiebreaker.
  static double _finalScore(double rep, double loc, double val,
      BudgetClass bc, bool isBooked, double overBudgetRatio) {
    final base = switch (bc) {
      BudgetClass.highClass => rep * 0.75 + loc * 0.15 + val * 0.10,
      BudgetClass.flexible => rep * 0.30 + val * 0.30 + loc * 0.40,
      BudgetClass.budgetFriendly => val * 0.70 + loc * 0.15 + rep * 0.15,
    };
    final penalized = isBooked ? base - _bookedPenalty : base;
    return penalized - overBudgetRatio * _overBudgetWeight;
  }

  /// Mirrors the 4 named steps the real AI matcher is prompted to return
  /// (see the /api/vendor-match prompt), so the offline fallback reads the
  /// same way as a live AI pick instead of one run-on sentence.
  static List<ReasoningStep> _reasonSteps(
    VendorProfile v,
    BudgetClass bc,
    int rankInCat,
    bool isBooked,
    double? categoryBudget,
    double overBudgetRatio,
    List<String> styles,
    double locationScore,
    double effectivePrice,
    int? guestCount,
  ) {
    final stars = v.rating?.toStringAsFixed(1) ?? '—';
    final rev = v.feedbackCount;
    final cat = v.category;

    final String budgetText;
    if (categoryBudget == null) {
      // Total budget is guaranteed to be set by this point (see the
      // NoBudgetSetException guard above) — this only fires for a custom
      // category the couple added that has no default allocation percentage,
      // so there's no per-category split to compare price against.
      budgetText = 'No specific allocation set for $cat yet, so price wasn\'t used as a filter here.';
    } else if (overBudgetRatio <= 0) {
      budgetText = 'You have been allocated ~${categoryBudget.toStringAsFixed(0)} for $cat.';
    } else {
      budgetText =
          'Starts around ${effectivePrice.toStringAsFixed(0)}, above the ~${categoryBudget.toStringAsFixed(0)} '
          'you were allocated for $cat — still the closest available fit. You can move forward by asking '
          'for a smaller/custom package, trimming scope for $cat, or shifting budget from a lower-priority category.';
    }

    // Capacity is the dominant ranking signal (see _AiEngine.recommend), so
    // the couple should see exactly why in terms of their own headcount —
    // not just that a number is on file. Omitted only when there's neither a
    // guest count to compare against nor a stated capacity to show. The
    // headcount claim is made about the listing that actually seats the party
    // (fittingGuestCapacity — the same figure _capacityRank ranked on), never
    // the vendor's largest listing, which would otherwise overstate the fit or
    // — for a vendor who only qualified on a capacity-less listing — claim a
    // "fit above your headcount" that is in fact below it.
    final capacity = v.maxGuestCapacity;
    final fitting =
        (guestCount != null && guestCount > 0) ? v.fittingGuestCapacity(guestCount) : null;
    final String? guestCapacityText;
    if (guestCount != null && guestCount > 0 && fitting != null) {
      guestCapacityText = fitting == guestCount
          ? 'Serves exactly $fitting guests — an exact capacity match for your $guestCount-guest wedding.'
          : 'Serves up to $fitting guests — the closest available fit above your $guestCount-guest headcount.';
    } else if (guestCount != null && guestCount > 0) {
      guestCapacityText =
          "Hasn't stated a firm capacity covering $guestCount guests, so this wasn't held against them — treated as neutral, not excluded. Confirm your party size with them directly.";
    } else if (capacity != null) {
      guestCapacityText = 'Serves up to $capacity guests.';
    } else {
      guestCapacityText = null;
    }

    final reputationText = v.rating == null
        ? 'New to WedPilot — no client ratings yet, so this pick leaned on price and profile fit instead.'
        : '$stars★ from $rev verified ${rev == 1 ? 'client' : 'clients'}${(v.recommendRate != null && v.recommendRate! > 0) ? ', ${(v.recommendRate! * 100).round()}% would recommend' : ''}.';

    final availabilityText = isBooked
        ? 'Already booked on your wedding date — confirm availability before relying on them, or line up a backup in $cat.'
        : 'Open on your wedding date, based on their calendar.';

    // Proximity is treated as a high-priority factor, so it's always called
    // out plainly before style — the couple should know whether "near you"
    // is why this pick won, or whether it's a trade-off they should weigh.
    final locationName = (v.location?.isNotEmpty ?? false) ? v.location! : null;
    final String proximityText;
    if (locationName == null) {
      proximityText = '';
    } else if (locationScore >= 0.7) {
      proximityText = 'Located in $locationName — close to you, prioritized as a top match for proximity. ';
    } else if (locationScore <= 0.35) {
      proximityText = 'Located in $locationName — further from you, so this weighed against them here. ';
    } else {
      proximityText = 'Located in $locationName. ';
    }

    final overlap = styles
        .where((pref) => v.styleTags.any((tag) => tag.toLowerCase() == pref.toLowerCase()))
        .toList();
    final styleText = proximityText +
        (overlap.isNotEmpty
            ? 'Matches your ${overlap.join(', ')} style preference${overlap.length > 1 ? 's' : ''}.'
            : v.styleTags.isNotEmpty
                ? 'Known for ${v.styleTags.take(2).join(', ')} — no direct overlap with your stated style, but still strong in $cat.'
                : 'No style tags on file to compare against your preferences.');

    final String verdictText;
    if (isBooked) {
      verdictText =
          'Ranked #$rankInCat in $cat on quality, but the date conflict makes this a backup unless they confirm availability.';
    } else if (categoryBudget != null && overBudgetRatio > 0) {
      verdictText = 'Best available pick in $cat given the budget gap — worth the package conversation above.';
    } else {
      verdictText = switch (bc) {
        BudgetClass.highClass => rankInCat == 1
            ? 'Top luxury pick in $cat — $stars★ from $rev verified clients, the premier choice for an extraordinary wedding.'
            : 'Premium-tier excellence in $cat · $stars★, curated for couples who expect only the finest.',
        BudgetClass.flexible => rankInCat == 1
            ? 'Best overall value in $cat · $stars★ from $rev couples — the highest quality-to-price ratio across all tiers.'
            : 'Excellent balanced pick in $cat · $stars★, strong on quality, price, and location.',
        BudgetClass.budgetFriendly => rankInCat == 1
            ? 'Top affordable choice in $cat · $stars★ · $rev satisfied couples — best quality at the right price.'
            : 'Smart budget pick in $cat · $stars★, proven reliability without overspending.',
      };
    }

    final steps = [
      if (guestCapacityText != null)
        ReasoningStep(label: ReasoningStep.guestCapacity, text: guestCapacityText),
      ReasoningStep(label: ReasoningStep.budgetFit, text: budgetText),
      ReasoningStep(label: ReasoningStep.reputation, text: reputationText),
      ReasoningStep(label: ReasoningStep.availability, text: availabilityText),
      ReasoningStep(label: ReasoningStep.styleMatch, text: styleText),
      ReasoningStep(label: ReasoningStep.verdict, text: verdictText),
    ];

    return steps;
  }

}

class _ScoredVendor {
  final VendorProfile vendor;
  final double reputation;
  final double location;
  final double value;
  final double finalScore;
  final bool isBookedOnWeddingDate;
  final double? categoryBudget;
  final double overBudgetRatio;
  final VendorPriceTier priceTier;

  /// Class-adjusted price every budget figure is computed from — see
  /// [VendorProfile.priceForClass] (registered package price for the class
  /// when the vendor has one, else the vendor's price range).
  final double effectivePrice;

  /// See [_AiEngine._capacityRank] — the dominant primary sort key in
  /// [_AiEngine.recommend].
  final int capacityRank;

  /// The couple's headcount this vendor was scored against — carried
  /// alongside [capacityRank] purely so reasoning text (see
  /// `_AiEngine._reasonSteps`) can tell "exact match" apart from "no guest
  /// count was entered", both of which produce a `capacityRank` of 0.
  final int? guestCount;

  const _ScoredVendor({
    required this.vendor,
    required this.reputation,
    required this.location,
    required this.value,
    required this.finalScore,
    this.isBookedOnWeddingDate = false,
    this.categoryBudget,
    this.overBudgetRatio = 0.0,
    this.priceTier = VendorPriceTier.mid,
    this.effectivePrice = 0.0,
    this.capacityRank = 0,
    this.guestCount,
  });
}
