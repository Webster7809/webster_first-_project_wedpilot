import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/class_packages.dart';
import '../../../core/utils/pdf_download.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/inquiry_status_display.dart';
import '../../../models/messaging.dart';
import '../../../models/vendor_profile.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/vendor_ai_provider.dart';
import '../../../providers/vendor_provider.dart';
import '../../../providers/vendor_wizard_provider.dart';
import '../../../widgets/booking_action_button.dart'
    show BookingActionButton, confirmAndCancelBooking;
import '../../../widgets/loading_shimmer.dart';
import '../../../widgets/wed_avatar.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_snack_bar.dart';
import '../../../widgets/wed_text_field.dart';
import '../../../widgets/wizard_widgets.dart';

class CouplePlanningScreen extends ConsumerStatefulWidget {
  const CouplePlanningScreen({super.key});

  @override
  ConsumerState<CouplePlanningScreen> createState() =>
      _CouplePlanningScreenState();
}

class _CouplePlanningScreenState extends ConsumerState<CouplePlanningScreen> {
  int _step = 0;
  static const int _totalSteps = 4;

  // Step 0 — Budget & basics
  final _budgetCtrl = TextEditingController();
  final _guestsCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _weddingType = 'White wedding';
  String _weddingClass = 'Flexible';
  // Categories the couple has ticked. The selectable list itself is dynamic —
  // built-in categories merged with whatever categories vendors have actually
  // registered under (see availableVendorCategoriesProvider).
  final Set<String> _selectedCategories = {};

  // Step 1 — Date
  DateTime? _weddingDate;

  // Step 2 — Style
  final _styleOptions = [
    'Elegant',
    'Rustic',
    'Modern',
    'Bohemian',
    'Traditional',
    'Minimalist',
  ];
  final List<String> _selectedStyles = [];

  // Anchors for each category's AI-matched vendor section in the review step,
  // so the "Vendors needed" chips can jump straight to the picked vendor.
  final Map<String, GlobalKey> _categorySectionKeys = {};

  GlobalKey _categorySectionKey(String category) =>
      _categorySectionKeys.putIfAbsent(category, () => GlobalKey());

  void _scrollToCategory(String category) {
    final ctx = _categorySectionKeys[category]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.06,
    );
  }

  static const _stepLabels = [
    "LET'S PLAN YOUR DAY",
    'YOUR WEDDING DATE',
    'STYLE & PREFERENCES',
    'YOUR WEDDING PLAN',
  ];

  static const _stepTitles = [
    "What's your total\nwedding budget?",
    "When's your\nbig day?",
    "What's your\nwedding style?",
    "Your AI-curated\nwedding plan",
  ];

  @override
  void dispose() {
    _budgetCtrl.dispose();
    _guestsCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  List<String> _availableCategories() =>
      ref.read(availableVendorCategoriesProvider).valueOrNull ??
      AppConstants.vendorCategories;

  List<String> _activeCategories() {
    // Preserve the checklist's display order rather than tick order.
    final selected =
        _availableCategories().where(_selectedCategories.contains).toList();
    return selected.isNotEmpty
        ? selected
        : List.of(AppConstants.vendorCategories);
  }

  double? _parsedBudget() => double.tryParse(
        _budgetCtrl.text.replaceAll(',', '').replaceAll(' ', ''),
      );

  void _next() {
    if (_step == 0) {
      final budget = _parsedBudget();
      if (budget == null || budget <= 0) {
        showWedSnackBar(
          context,
          "You haven't entered a wedding budget yet — WedPilot AI can't match "
          'vendors until it knows how much you intend to spend. Please add an amount.',
          type: SnackType.error,
        );
        return;
      }
      final guestCount = int.tryParse(_guestsCtrl.text.trim());
      if (guestCount == null || guestCount <= 0) {
        showWedSnackBar(
          context,
          "You haven't entered your guest count yet — WedPilot AI needs it to check "
          'which vendors can actually accommodate your wedding size. Please add a '
          'number greater than zero.',
          type: SnackType.error,
        );
        return;
      }
      if (guestCount > AppConstants.maxRealisticGuestCount) {
        showWedSnackBar(
          context,
          'That guest count looks unrealistic — please enter a number no greater '
          'than ${AppConstants.maxRealisticGuestCount}.',
          type: SnackType.error,
        );
        return;
      }
      // Coarse, system-wide sanity gate: if every vendor on file states a
      // capacity and every single one of them is smaller than this, nobody in
      // the system could ever serve this wedding regardless of category or
      // location, so there's no reason to let the couple sink three more
      // wizard steps into a plan that can only fail. Skipped entirely (null)
      // until vendor data has loaded or no vendor has stated a capacity —
      // the precise, category/location-scoped check still runs later in
      // vendorMatchValidationProvider either way.
      final systemMaxCapacity =
          ref.read(systemMaxGuestCapacityProvider).valueOrNull;
      if (systemMaxCapacity != null && guestCount > systemMaxCapacity) {
        showWedSnackBar(
          context,
          'No vendor in our system currently states a serving capacity that '
          'large — the largest on file is $systemMaxCapacity guests. Please '
          'reduce your guest count, or check back once more vendors have '
          'registered.',
          type: SnackType.error,
        );
        return;
      }
      // Ticking nothing used to fall through _activeCategories()' "no
      // selection means all of them" default, so a couple who skipped this
      // silently got a plan covering every category on file — including ones
      // they had no intention of hiring. Asking is better than guessing.
      final chosenCategories =
          _availableCategories().where(_selectedCategories.contains).toList();
      if (chosenCategories.isEmpty) {
        showWedSnackBar(
          context,
          'Tick the services you need — WedPilot AI plans and budgets for the '
          'categories you choose, so it needs at least one to work with.',
          type: SnackType.error,
        );
        return;
      }

      ref.read(selectedServiceCategoriesProvider.notifier).state =
          chosenCategories;
      ref.read(wizardLocationProvider.notifier).state = _locationCtrl.text
          .trim();
      ref.read(wizardBudgetProvider.notifier).state = budget;
      ref.read(wizardGuestCountProvider.notifier).state =
          int.tryParse(_guestsCtrl.text.trim());
    }

    if (_step == 1 && _weddingDate == null) {
      showWedSnackBar(
        context,
        "You haven't picked your wedding date yet — it decides which vendors "
        'are actually free, so WedPilot AI needs it before it can match anyone.',
        type: SnackType.error,
      );
      return;
    }

    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    }
  }

  Future<void> _saveProfile() async {
    await ref
        .read(authProvider.notifier)
        .updateCoupleProfile(
          selectedItems: _activeCategories(),
          budget:
              double.tryParse(
                _budgetCtrl.text.replaceAll(',', '').replaceAll(' ', ''),
              ) ??
              0,
          weddingStyle: _weddingType,
          weddingClass: _weddingClass,
          guestCount: int.tryParse(_guestsCtrl.text) ?? 0,
          location: _locationCtrl.text.trim(),
          weddingDate: _weddingDate,
        );
    final error = ref.read(authProvider).error;
    if (error != null && mounted) {
      showWedSnackBar(context, error, type: SnackType.error);
      ref.read(authProvider.notifier).clearError();
    }
  }

  void _createPlan() {
    // Guards against a fast double-tap/double-click firing this twice before
    // the step-3 rebuild removes this button — _step flips to 3 synchronously
    // below, so this check alone is enough to reject the second call.
    if (_step != 2) return;
    final totalBudget = _parsedBudget() ?? 0;
    if (totalBudget <= 0) {
      showWedSnackBar(
        context,
        "You haven't entered a wedding budget yet — WedPilot AI can't match "
        'vendors until it knows how much you intend to spend. Please add an amount.',
        type: SnackType.error,
      );
      setState(() => _step = 0);
      return;
    }
    // The last step is a step, not a decoration: style is what separates two
    // vendors with identical price and rating, and an unanswered style step
    // quietly drops that signal out of every match.
    if (_selectedStyles.isEmpty) {
      showWedSnackBar(
        context,
        'Pick the style that fits your day — WedPilot AI uses it to choose '
        'between vendors that are otherwise an equally good match.',
        type: SnackType.error,
      );
      return;
    }
    unawaited(_saveProfile());
    // Matching itself always fetches fresh, category-scoped data (see
    // vendorMatchValidationProvider), so this invalidate is only for the
    // other, unscoped consumers of the full vendor pool — recommendedVendorsProvider
    // and availableVendorCategoriesProvider — so packages/ratings vendors
    // registered since the last fetch reach those too, not a session-old list.
    ref.invalidate(allVendorsProvider);
    final categories = _activeCategories();
    ref.read(selectedServiceCategoriesProvider.notifier).state = categories;
    ref.read(wizardLocationProvider.notifier).state = _locationCtrl.text.trim();
    ref.read(wizardBudgetProvider.notifier).state = totalBudget;
    ref.read(wizardGuestCountProvider.notifier).state =
        int.tryParse(_guestsCtrl.text.trim());
    ref.read(wizardStylesProvider.notifier).state = _selectedStyles.toList();
    ref.read(budgetClassProvider.notifier).state = switch (_weddingClass) {
      'Low class' => BudgetClass.budgetFriendly,
      'High class' => BudgetClass.highClass,
      _ => BudgetClass.flexible,
    };
    ref
        .read(budgetProvider.notifier)
        .loadBudget(
          total: totalBudget,
          currency: 'ZMW',
          serviceCategories: categories,
        );
    setState(() => _step++);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SingleChildScrollView(
          key: ValueKey(_step),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WizardHeader(
                step: _step,
                totalSteps: _totalSteps,
                stepLabel: _stepLabels[_step],
                stepTitle: _stepTitles[_step],
                backgroundAssets: const [
                  'assets/images/onboarding/couple_1.jpg',
                  'assets/images/onboarding/couple_2.jpg',
                  'assets/images/onboarding/couple_3.jpg',
                  'assets/images/onboarding/couple_4.jpg',
                ],
                onBack: _step > 0 ? () => setState(() => _step--) : null,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: _buildStep(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildBudgetStep();
      case 1:
        return _buildDateStep();
      case 2:
        return _buildStyleStep();
      case 3:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }

  // ── Step 0: Budget & basics ─────────────────────────────────────────────────

  Widget _buildBudgetStep() {
    // Watched here (not read lazily in _next()) so the system-wide guest
    // capacity gate almost always has data by the time the couple taps
    // Continue, instead of a network round-trip only starting on submit —
    // and so its value is available below as an upfront clue, not just in
    // the rejection message once they've already typed an unrealistic number.
    final systemMaxCapacity =
        ref.watch(systemMaxGuestCapacityProvider).valueOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Budget input
        WizardSectionLabel(
          icon: Icons.credit_card_outlined,
          label: 'Total wedding budget',
        ),
        const SizedBox(height: 10),
        _BudgetField(controller: _budgetCtrl),
        const SizedBox(height: 8),
        Text(
          'This helps WedPilot match vendors within your range — you can adjust anytime.',
          style: AppTextStyles.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        // Wedding type
        WizardSectionLabel(
          icon: Icons.favorite_outlined,
          label: 'Type of wedding',
        ),
        const SizedBox(height: 10),
        _TypePills(
          options: const ['White wedding', 'Traditional'],
          selected: _weddingType,
          onChanged: (v) => setState(() => _weddingType = v),
        ),
        const SizedBox(height: 24),

        // Guest count
        WizardSectionLabel(
          icon: Icons.people_outlined,
          label: 'Number of guests',
        ),
        const SizedBox(height: 10),
        _PlanField(
          controller: _guestsCtrl,
          hint: '150',
          inputType: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        if (systemMaxCapacity != null) ...[
          const SizedBox(height: 8),
          Text(
            'Vendors on file can currently serve up to $systemMaxCapacity guests.',
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Location
        WizardSectionLabel(
          icon: Icons.location_on_outlined,
          label: 'Wedding location',
        ),
        const SizedBox(height: 10),
        _PlanField(
          controller: _locationCtrl,
          hint: 'Ndola, Copperbelt',
          inputType: TextInputType.text,
        ),
        const SizedBox(height: 24),

        // Wedding class
        WizardSectionLabel(
          icon: Icons.credit_card_outlined,
          label: 'Choose your wedding class',
        ),
        const SizedBox(height: 10),
        _WeddingClassCards(
          selected: _weddingClass,
          onChanged: (v) => setState(() => _weddingClass = v),
        ),
        const SizedBox(height: 24),

        // Vendor categories — a tickable checklist. The list itself is live:
        // built-in categories plus any category a vendor has registered under.
        WizardSectionLabel(
          icon: Icons.grid_view_outlined,
          label: 'Vendors you\'ll need',
        ),
        const SizedBox(height: 10),
        _CategoryChecklist(
          categories: ref.watch(availableVendorCategoriesProvider).valueOrNull ??
              AppConstants.vendorCategories,
          selected: _selectedCategories,
          onToggle: (cat) => setState(() {
            if (!_selectedCategories.remove(cat)) {
              _selectedCategories.add(cat);
            }
          }),
        ),
        const SizedBox(height: 6),
        Text(
          'Tick every service you need — WedPilot AI will search and rank the best match for each.',
          style: AppTextStyles.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        WedButton(onPressed: _next, label: 'Continue'),
      ],
    );
  }

  // ── Step 1: Date ────────────────────────────────────────────────────────────

  Widget _buildDateStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WizardSectionLabel(
          icon: Icons.calendar_today_outlined,
          label: 'Select your wedding date',
        ),
        const SizedBox(height: 16),
        Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _weddingDate ?? DateTime(2026, 9, 12),
              firstDate: DateTime.now(),
              lastDate: DateTime(2030),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.forestGreen,
                    secondary: AppColors.amber,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _weddingDate = picked);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _weddingDate != null
                    ? AppColors.forestGreen
                    : AppColors.divider,
                width: _weddingDate != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: _weddingDate != null
                      ? AppColors.forestGreen
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _weddingDate != null
                        ? '${_weekday(_weddingDate!)}, ${_weddingDate!.day} ${_month(_weddingDate!)} ${_weddingDate!.year}'
                        : 'Tap to pick your date',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: _weddingDate != null
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
        const SizedBox(height: 32),
        WedButton(onPressed: _next, label: 'Continue'),
      ],
    );
  }

  // ── Step 2: Style ───────────────────────────────────────────────────────────

  Widget _buildStyleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pick the vibe that describes your dream wedding — choose a '
          'primary style, and optionally a second.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _styleOptions.map((style) {
            final index = _selectedStyles.indexOf(style);
            final selected = index != -1;
            final isPrimary = index == 0;
            final selectedColor =
                isPrimary ? AppColors.forestGreen : AppColors.tertiary;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => setState(() {
                  if (selected) {
                    _selectedStyles.remove(style);
                  } else if (_selectedStyles.length < 2) {
                    _selectedStyles.add(style);
                  } else {
                    // Two are already selected — swap this in as the new
                    // secondary and leave the primary (index 0) untouched.
                    _selectedStyles[1] = style;
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? selectedColor : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: selected ? selectedColor : AppColors.divider,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        style,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 6),
                        Text(
                          isPrimary ? 'PRIMARY' : '2ND',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white70,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        WedButton(
          onPressed: _createPlan,
          label: 'Create our wedding plan',
        ),
      ],
    );
  }

  // ── Step 3: AI-curated review ───────────────────────────────────────────────

  Widget _buildReviewStep() {
    final aiAsync = ref.watch(aiRecommendedVendorsProvider);
    final validationResult = ref.watch(vendorMatchValidationProvider).valueOrNull;
    final excludedCategoryMessages =
        validationResult?.excludedCategoryMessages ?? const <String, String>{};
    final budgetExhaustedMessages =
        validationResult?.budgetExhaustedMessages ?? const <String, String>{};
    final guestCapacityExcludedMessages =
        validationResult?.guestCapacityExcludedMessages ?? const <String, String>{};
    // Categories already committed to a vendor via a live booking request.
    // These are rendered from the request itself and never re-matched.
    final lockedCategories =
        validationResult?.lockedCategories ?? const <String, LockedCategoryRequest>{};
    final pdfAsync = ref.watch(weddingPlanPdfBytesProvider);
    final categories = _activeCategories();
    final budgetClass = ref.watch(budgetClassProvider);

    // Real spend so far — the sum of what the AI's actually-picked vendors
    // charge (never a computed/estimated figure), shown against the couple's
    // entered total once matching has resolved at least one real price.
    // Must read priceForClass(budgetClass) — the exact figure the ledger
    // budgeted against and the one shown as "Package price" on each vendor
    // card — never the raw priceMin, which can be a completely different,
    // unrelated number once a vendor has a class-specific package price on file.
    final totalBudgetAmount = _parsedBudget();
    // Requested vendors count as spent too — that money is committed even
    // though the AI never picked them this run. Leaving them out would show a
    // "Remaining" figure the couple can't actually spend.
    final lockedSpend = lockedCategories.values
        .map((l) => l.vendor.priceForClass(budgetClass))
        .where((p) => p > 0)
        .fold<double>(0, (sum, p) => sum + p);
    final usedAmount = (aiAsync.valueOrNull ?? const <VendorMatch>[])
            .where((m) => m.rankInCategory == 1 && m.vendor.priceForClass(budgetClass) > 0)
            .fold<double>(0, (sum, m) => sum + m.vendor.priceForClass(budgetClass)) +
        lockedSpend;
    final hasRealUsage =
        totalBudgetAmount != null && totalBudgetAmount > 0 && usedAmount > 0;
    final remainingAmount = hasRealUsage ? totalBudgetAmount - usedAmount : null;
    final budget = totalBudgetAmount != null && totalBudgetAmount > 0
        ? fmtCurrency(totalBudgetAmount)
        : _budgetCtrl.text.isNotEmpty
            ? 'ZMW ${_budgetCtrl.text}'
            : 'Not set';
    final guests = _guestsCtrl.text.isNotEmpty
        ? '${_guestsCtrl.text} guests'
        : 'Not set';
    final location = _locationCtrl.text.isNotEmpty
        ? _locationCtrl.text
        : 'Not set';
    final dateStr = _weddingDate != null
        ? '${_weddingDate!.day} ${_month(_weddingDate!)} ${_weddingDate!.year}'
        : 'Not set';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WizardSectionLabel(
          icon: Icons.auto_awesome,
          label: 'AI-matched vendors',
        ),
        const SizedBox(height: 4),
        Text(
          'WedPilot AI picks one best-fit vendor per category — based in your entered location and '
          'weighed against your allocated budget for that category.',
          style: AppTextStyles.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        _AiDisclaimer(color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(height: 14),
        aiAsync.when(
          // Booking a Top Pick vendor invalidates myBookingsProvider so the
          // matcher stops re-suggesting it — activeRequestsByVendorProvider
          // and this provider both cascade-reload as a result. Without this,
          // that reload flashes the full "AI matching" spinner over the
          // whole list on every single booking tap, as if a fresh match was
          // being computed from scratch. skipLoadingOnReload keeps the
          // already-ranked list on screen while it quietly recomputes in the
          // background; the spinner stays reserved for the real first match.
          skipLoadingOnReload: true,
          loading: () => const _AiRankingCard(),
          error: (e, st) {
            if (e is NoBudgetSetException) {
              return _NoBudgetCard(onEnterBudget: () => setState(() => _step = 0));
            }
            if (e is VendorValidationException) {
              return _VendorValidationFailureCard(
                failure: e.failure,
                onEditRequirements: () => setState(() => _step = 0),
              );
            }
            return Text(
              "Couldn't reach WedPilot AI right now. Please try again in a moment.",
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          },
          data: (matches) {
            // Every card ships with deterministic, locally-authored reasoning
            // the instant matches resolve (see aiRecommendedVendorsProvider).
            // The AI writes richer justification for the same, already-final
            // pick in the background and never blocks this screen — once it
            // lands here, swap it in without re-running the match itself.
            final explanations = ref.watch(vendorMatchExplanationsProvider);
            final explainedMatches = [
              for (final m in matches) _applyAiExplanation(m, explanations[m.vendor.category]),
            ];

            // Up to 3 per category (rank 1-3, sorted), not just the winner —
            // seeing the runners-up alongside the top pick is what actually
            // lets a couple sanity-check the ranking instead of trusting a
            // single name on faith (see AiEngine.attachAlternates).
            final rankedByCategory = <String, List<VendorMatch>>{};
            for (final m in explainedMatches) {
              rankedByCategory.putIfAbsent(m.vendor.category, () => []).add(m);
            }
            for (final list in rankedByCategory.values) {
              list.sort((a, b) => a.rankInCategory.compareTo(b.rankInCategory));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final category in categories) ...[
                  WizardSectionLabel(
                    key: _categorySectionKey(category),
                    icon: categoryIcon(category),
                    label: category,
                  ),
                  const SizedBox(height: 10),
                  // A category the couple already committed to is answered by
                  // that request — it deliberately never reaches the matcher,
                  // so it's rendered before every other branch here.
                  if (lockedCategories[category] != null)
                    _RequestedVendorCard(locked: lockedCategories[category]!)
                  else if ((rankedByCategory[category]?.isNotEmpty ?? false))
                    for (final match in rankedByCategory[category]!.take(3)) ...[
                      _PlanVendorCard(
                        match: match,
                        budgetClass: ref.watch(budgetClassProvider),
                      ),
                      const SizedBox(height: 10),
                    ]
                  else if (budgetExhaustedMessages[category] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.money_off,
                            size: 16,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              budgetExhaustedMessages[category]!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (guestCapacityExcludedMessages[category] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.warningBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.people_outlined,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              guestCapacityExcludedMessages[category]!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      excludedCategoryMessages[category] ??
                          'No available $category vendors matched yet.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 18),
                ],
                const SizedBox(height: 20),
                // ── Wedding details recap ─────────────────────────────────────
                // Sits below the matched vendors, not above — there's nothing
                // to recap yet until the AI has actually aligned vendors, so
                // it's skipped entirely when matching came back empty.
                if (matches.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        _SummaryRow(label: 'Budget', value: budget),
                        if (hasRealUsage) ...[
                          _SummaryRow(
                              label: 'Budget used',
                              value: fmtCurrency(usedAmount)),
                          _SummaryRow(
                            label: 'Remaining',
                            value: remainingAmount! > 0
                                ? fmtCurrency(remainingAmount)
                                : remainingAmount < 0
                                    ? 'Over by ${fmtCurrency(remainingAmount.abs())}'
                                    : 'All budget used',
                          ),
                        ],
                        _SummaryRow(label: 'Wedding type', value: _weddingType),
                        _SummaryRow(label: 'Wedding class', value: _weddingClass),
                        _SummaryRow(label: 'Guests', value: guests),
                        _SummaryRow(label: 'Location', value: location),
                        _SummaryRow(label: 'Date', value: dateStr),
                        _VendorsNeededRow(
                          categories: categories,
                          onCategoryTap: _scrollToCategory,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        pdfAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.forestGreen),
            ),
          ),
          error: (e, st) => Text(
            'Could not prepare your plan document. Please try again.',
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          data: (bytes) => WedButton(
            label: 'Download PDF',
            icon: const Icon(Icons.download),
            variant: WedButtonVariant.secondary,
            onPressed: () async {
              if (bytes.isEmpty) return;
              if (kIsWeb) {
                await downloadPdfFile('wedpilot-wedding-plan.pdf', bytes);
              } else {
                await Printing.sharePdf(
                  bytes: bytes,
                  filename: 'wedpilot-wedding-plan.pdf',
                );
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        WedButton(
          onPressed: () => context.go('/couple/dashboard'),
          label: 'Go to Dashboard',
        ),
      ],
    );
  }

  String _month(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[d.month - 1];
  }

  String _weekday(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }
}

// ── Category icon lookup ────────────────────────────────────────────────────

IconData categoryIcon(String category) {
  switch (category) {
    case 'Venue':
      return Icons.location_city;
    case 'Catering':
      return Icons.restaurant;
    case 'Photography':
      return Icons.camera_alt;
    case 'Decor & flowers':
      return Icons.local_florist;
    case 'DJ & MC':
      return Icons.music_note;
    case 'Transport':
      return Icons.directions_car;
    case 'Wedding attire':
      return Icons.checkroom;
    case 'Cake & sweets':
      return Icons.cake;
    default:
      return Icons.storefront;
  }
}

// ── AI ranking indicator ────────────────────────────────────────────────────

class _AiRankingCard extends StatefulWidget {
  const _AiRankingCard();

  @override
  State<_AiRankingCard> createState() => _AiRankingCardState();
}

class _AiRankingCardState extends State<_AiRankingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.forestGreen.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.forestGreen.withAlpha(60)),
          ),
          child: Row(
            children: [
              RotationTransition(
                turns: _controller,
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.forestGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Finding your best matching vendors — checking budget, location, '
                  'guest capacity, and reputation for each category…',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const VendorCardShimmer(),
        const SizedBox(height: 12),
        const VendorCardShimmer(),
      ],
    );
  }
}

// ── No-budget notice — blocks AI vendor matching until one is entered ──────

class _NoBudgetCard extends StatelessWidget {
  final VoidCallback onEnterBudget;

  const _NoBudgetCard({required this.onEnterBudget});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amber.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.savings_outlined,
                color: AppColors.goldDeep,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "You haven't entered a wedding budget yet",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "WedPilot AI won't recommend or rank any vendor until it knows how "
            "much you intend to spend — price is part of every match it makes. "
            'Please go back and add your total budget.',
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          WedButton(
            label: 'Enter your budget',
            onPressed: onEnterBudget,
            width: 200,
            height: 40,
          ),
        ],
      ),
    );
  }
}

// ── Vendor validation failure — hard stop before any AI runs ────────────────

class _VendorValidationFailureCard extends StatelessWidget {
  final VendorValidationFailure failure;
  final VoidCallback onEditRequirements;

  const _VendorValidationFailureCard({
    required this.failure,
    required this.onEditRequirements,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amber.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber,
                color: AppColors.goldDeep,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "We couldn't build your plan yet",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            failure.message,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          WedButton(
            label: 'Edit requirements',
            onPressed: onEditRequirements,
            width: 200,
            height: 40,
          ),
        ],
      ),
    );
  }
}

// ── Plan vendor card — the AI's top pick, with contact details ─────────────

/// A category the couple already sent a booking request for.
///
/// Shown in place of an AI pick, because the request *is* the decision for
/// that category — re-running the plan must not re-propose the same vendor or
/// quietly swap them for someone else. Cancelling here hands the category back
/// to the matcher on the next run.
class _RequestedVendorCard extends ConsumerWidget {
  final LockedCategoryRequest locked;

  const _RequestedVendorCard({required this.locked});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendor = locked.vendor;
    final display = InquiryStatusDisplay.of(locked.inquiry.status);
    final price = vendor.priceForClass(ref.watch(budgetClassProvider));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: display.color.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              WedAvatar(imageUrl: vendor.logoUrl, name: vendor.businessName, radius: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  vendor.businessName,
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _Badge(label: display.label, color: display.color),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outlined, size: 14, color: AppColors.goldDeep),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "You've already requested this vendor, so WedPilot AI left "
                  '${vendor.category} as you decided it.',
                  style: AppTextStyles.caption.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (price > 0) ...[
            const SizedBox(height: 8),
            _ContactChip(
              icon: Icons.sell_outlined,
              text: 'Package price ${fmtCurrency(price)}',
            ),
          ],
          // Once the vendor has approved, self-serve cancel goes away — see
          // the note on booking_action_button.dart's confirmAndCancelBooking
          // for why.
          if (locked.inquiry.status != InquiryStatus.booked) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () =>
                    confirmAndCancelBooking(context, ref, locked.inquiry),
                child: Text(
                  'Cancel request',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanVendorCard extends StatelessWidget {
  final VendorMatch match;

  /// Wedding class the plan was built for — drives the bundled package shown
  /// on AI picks (High Class: full luxury package, Flexible: starter package,
  /// Budget-Friendly: none).
  final BudgetClass? budgetClass;

  const _PlanVendorCard({required this.match, this.budgetClass});

  @override
  Widget build(BuildContext context) {
    final v = match.vendor;
    final servicesText = v.services.isNotEmpty
        ? v.services.map((s) => s.title).join(', ')
        : (v.description ?? '');
    final priceText = v.priceMax > 0
        ? '${fmtCurrency(v.priceMin)} – ${fmtCurrency(v.priceMax)}'
        : null;
    // The package shown with a class pick: the vendor's own registered
    // package for that tier when they have one (their real, syncing offer —
    // exactly what the couple gets and why the class is worth it), falling
    // back to the standard class package catalog otherwise. Budget-Friendly
    // gets neither by design.
    final wantedTier = switch (budgetClass) {
      BudgetClass.highClass => VendorPackageTier.luxury,
      BudgetClass.flexible => VendorPackageTier.starter,
      _ => null,
    };
    final vendorPackage = wantedTier != null
        ? v.packages
            .where((p) => p.tier == wantedTier && p.inclusions.isNotEmpty)
            .firstOrNull
        : null;
    final packageInclusions = vendorPackage?.inclusions ??
        (budgetClass != null
            ? ClassPackages.inclusionsFor(budgetClass!, v.category)
            : const <String>[]);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              WedAvatar(imageUrl: v.logoUrl, name: v.businessName, radius: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  v.businessName,
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const _Badge(
                label: 'AI top pick',
                color: AppColors.success,
              ),
            ],
          ),
          if (servicesText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              servicesText,
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              if ((v.location ?? '').isNotEmpty)
                _ContactChip(
                  icon: Icons.location_on_outlined,
                  text: v.location!,
                ),
              if ((v.phone ?? '').isNotEmpty)
                _ContactChip(
                  icon: Icons.call_outlined,
                  text: v.phone!,
                  onTap: () => launchUrl(Uri.parse('tel:${v.phone}')),
                ),
              if (priceText != null)
                _ContactChip(icon: Icons.sell_outlined, text: priceText),
              if (v.maxGuestCapacity != null)
                _ContactChip(
                  icon: Icons.groups_outlined,
                  text: 'Can serve up to: ${v.maxGuestCapacity} guests',
                ),
            ],
          ),
          if (packageInclusions.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ClassPackageSection(
              budgetClass: budgetClass!,
              inclusions: packageInclusions,
              vendorPackage: vendorPackage,
            ),
          ],
          if ((!match.fitsBudget ||
                  match.selectionBasis == SelectionBasis.onlyAffordableOption) &&
              (match.noteToCouple?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: match.isBudgetUnrealistic ? AppColors.errorBg : AppColors.warningBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    match.isBudgetUnrealistic
                        ? Icons.error_outlined
                        : Icons.info_outlined,
                    size: 14,
                    color: match.isBudgetUnrealistic ? AppColors.error : AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      match.noteToCouple!,
                      style: AppTextStyles.caption.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_visibleReasoningSteps(match).isNotEmpty) ...[
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final step in _visibleReasoningSteps(match))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _reasoningStepIcon(step.label),
                          size: 13,
                          color: AppColors.goldDeep,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.caption.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              children: [
                                TextSpan(
                                  text: '${step.label}: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(text: step.text),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ] else if (match.reasoning != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: AppColors.goldDeep,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    match.reasoning!,
                    style: AppTextStyles.caption.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          BookingActionButton(vendor: v),
        ],
      ),
    );
  }
}

/// The bundled package that comes with the couple's wedding class, rendered
/// on every AI pick. High Class gets the full dark-green/gold luxury
/// treatment so it visibly reads as premium; Flexible a modest cream card;
/// Budget-Friendly never reaches this widget (no package at all).
class _ClassPackageSection extends StatelessWidget {
  final BudgetClass budgetClass;
  final List<String> inclusions;

  /// The vendor's own registered package, when they have one for this tier —
  /// its title and price are shown so the couple sees the vendor's real
  /// offer, not just the generic class catalog.
  final VendorPackage? vendorPackage;

  const _ClassPackageSection({
    required this.budgetClass,
    required this.inclusions,
    this.vendorPackage,
  });

  @override
  Widget build(BuildContext context) {
    final isLuxury = budgetClass == BudgetClass.highClass;
    final label = ClassPackages.labelFor(budgetClass)!;
    final tagline = vendorPackage != null
        ? 'Registered by this vendor — exactly what comes with your booking.'
        : ClassPackages.taglineFor(budgetClass);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: isLuxury
            ? const LinearGradient(
                colors: [AppColors.forestGreen, AppColors.gradientAccentGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isLuxury ? null : AppColors.creamDark.withAlpha(120),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLuxury ? AppColors.amber : AppColors.divider,
          width: isLuxury ? 1.2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isLuxury ? Icons.workspace_premium : Icons.card_giftcard,
                size: 15,
                color: isLuxury ? AppColors.amber : AppColors.budgetGreen,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: isLuxury ? AppColors.amber : AppColors.budgetGreen,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          if (vendorPackage != null) ...[
            const SizedBox(height: 6),
            Text(
              vendorPackage!.title,
              style: AppTextStyles.titleMedium.copyWith(
                color: isLuxury ? Colors.white : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (tagline != null) ...[
            const SizedBox(height: 4),
            Text(
              tagline,
              style: AppTextStyles.caption.copyWith(
                color: isLuxury
                    ? Colors.white.withAlpha(200)
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 8),
          for (final item in inclusions)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isLuxury ? Icons.diamond_outlined : Icons.check,
                    size: 13,
                    color: isLuxury ? AppColors.amber : AppColors.budgetGreen,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTextStyles.caption.copyWith(
                        color: isLuxury ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (vendorPackage?.price != null) ...[
            const SizedBox(height: 4),
            Text(
              'Package price: ${fmtCurrency(vendorPackage!.price!)}',
              style: AppTextStyles.labelMedium.copyWith(
                color: isLuxury ? AppColors.amber : AppColors.forestGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// The couple already sees the category's allocated amount elsewhere on the
// card (and in the budget recap) — the "Budget fit" reasoning step just
// repeats that same figure, so it's dropped here while every other step
// (reputation, availability, style match, verdict) still renders as-is.
/// Overlays AI-authored reasoning onto an already-final [match] once it's
/// ready — [sug] is null until the background explanation call resolves, and
/// is discarded if it was written for a different vendor (a stale entry from
/// before the couple changed budget class/location and the pick moved on).
VendorMatch _applyAiExplanation(VendorMatch match, VendorMatchSuggestion? sug) {
  if (sug == null || sug.vendorId != match.vendorId) return match;
  return match.copyWith(
    reasoningSteps: sug.reasoningSteps,
    noteToCouple: sug.noteToCouple,
    fitsBudget: sug.fitsBudget,
    budgetDeltaPercent: sug.budgetDeltaPercent,
    selectionBasis: sug.selectionBasis,
  );
}

List<ReasoningStep> _visibleReasoningSteps(VendorMatch match) => match
    .reasoningSteps
    .where((s) => s.label != ReasoningStep.budgetFit)
    .toList();

IconData _reasoningStepIcon(String label) => switch (label) {
  ReasoningStep.guestCapacity => Icons.groups_outlined,
  ReasoningStep.budgetFit => Icons.payments_outlined,
  ReasoningStep.reputation => Icons.star_rate,
  ReasoningStep.availability => Icons.event_available_outlined,
  ReasoningStep.styleMatch => Icons.palette_outlined,
  ReasoningStep.verdict => Icons.auto_awesome,
  _ => Icons.auto_awesome,
};

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  const _ContactChip({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: child,
        ),
      ),
    );
  }
}

// ── Budget field ──────────────────────────────────────────────────────────────

class _BudgetField extends StatelessWidget {
  final TextEditingController controller;
  const _BudgetField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return WedTextField(
      controller: controller,
      hint: '85,000',
      prefixText: 'ZMW  ',
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d,]')),
      ],
    );
  }
}

// ── Plain plan field ──────────────────────────────────────────────────────────

class _PlanField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType inputType;
  final List<TextInputFormatter>? formatters;

  const _PlanField({
    required this.controller,
    required this.hint,
    this.inputType = TextInputType.text,
    this.formatters,
  });

  @override
  Widget build(BuildContext context) {
    return WedTextField(
      controller: controller,
      hint: hint,
      keyboardType: inputType,
      inputFormatters: formatters,
    );
  }
}

// ── Wedding type pills ────────────────────────────────────────────────────────

class _TypePills extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _TypePills({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) {
        final isSelected = opt == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: opt != options.last ? 8 : 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onChanged(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.forestGreen : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.forestGreen
                          : AppColors.divider,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Wedding class cards ───────────────────────────────────────────────────────

class _WeddingClassCards extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _WeddingClassCards({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const classes = [
      ('Low class', 'Budget-smart', Icons.wb_sunny_outlined),
      ('Flexible', 'Mix & match', Icons.trending_up),
      ('High class', 'Premium only', Icons.star_outlined),
    ];
    return Row(
      children: classes.map((c) {
        final (label, subtitle, icon) = c;
        final isSelected = selected == label;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: label != classes.last.$1 ? 8 : 0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onChanged(label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.amber.withAlpha(30)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.amber : AppColors.divider,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.amber
                            : AppColors.creamDark,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.amber
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Summary row ───────────────────────────────────────────────────────────────

// A collapsible drawer-style panel of vendor categories. Closed, it's a
// single tidy row summarising the selection; opened, it reveals a scrollable
// tick list (bounded height, so a growing category list — it expands as
// vendors register new services — never swallows the wizard page).
class _CategoryChecklist extends StatefulWidget {
  final List<String> categories;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _CategoryChecklist({
    required this.categories,
    required this.selected,
    required this.onToggle,
  });

  @override
  State<_CategoryChecklist> createState() => _CategoryChecklistState();
}

class _CategoryChecklistState extends State<_CategoryChecklist> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final count = widget.selected.length;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _expanded ? AppColors.amber : AppColors.divider,
          width: _expanded ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.checklist,
                        size: 20,
                        color: AppColors.goldDeep,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          count == 0
                              ? 'Select the services you need'
                              : '$count service${count == 1 ? '' : 's'} selected',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 22,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _expanded
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Divider(height: 1, color: AppColors.divider),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 280),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: widget.categories.length,
                              separatorBuilder: (_, _) => const Divider(
                                height: 1,
                                color: AppColors.divider,
                              ),
                              itemBuilder: (context, index) {
                                final category = widget.categories[index];
                                final isTicked =
                                    widget.selected.contains(category);
                                return InkWell(
                                  onTap: () => widget.onToggle(category),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isTicked
                                              ? Icons.check_box
                                              : Icons
                                                  .check_box_outline_blank_rounded,
                                          size: 22,
                                          color: isTicked
                                              ? AppColors.amber
                                              : Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            category,
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                              color: isTicked
                                                  ? Theme.of(context).colorScheme.onSurface
                                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                                              fontWeight: isTicked
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VendorsNeededRow extends StatelessWidget {
  final List<String> categories;
  final ValueChanged<String> onCategoryTap;

  const _VendorsNeededRow({
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Vendors needed',
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final category in categories)
                  InkWell(
                    onTap: () => onCategoryTap(category),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }
}

/// Shown wherever AI-generated reasoning is displayed — a plain reminder
/// that the couple should double-check specifics before acting on it, since
/// even a well-grounded model can still get a detail wrong.
class _AiDisclaimer extends StatelessWidget {
  final Color color;
  const _AiDisclaimer({this.color = Colors.white70});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outlined, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'AI-generated — it can make mistakes, so please double-check details before booking.',
            style: AppTextStyles.caption.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

