import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/wedding_ai_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/format_utils.dart';
import '../../../models/budget.dart';
import '../../../models/vendor_profile.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/vendor_ai_provider.dart';
import '../../../providers/vendor_provider.dart';
import '../../../providers/vendor_wizard_provider.dart';
import '../../../widgets/loading_shimmer.dart';
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
  static const int _totalSteps = 5;

  // Step 0 — Budget & basics
  final _budgetCtrl = TextEditingController();
  final _guestsCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _weddingType = 'White wedding';
  String _weddingClass = 'Flexible';
  final Map<String, bool> _vendorCategories = {
    'Venue': false,
    'Catering': false,
    'Photography': false,
    'Decor & flowers': false,
    'DJ & MC': false,
    'Transport': false,
    'Wedding attire': false,
    'Cake & sweets': false,
  };
  final _customCategoryCtrl = TextEditingController();
  final List<String> _customCategories = [];

  // Step 1 — Date
  DateTime? _weddingDate;

  // Step 2 — Style
  final _styleOptions = ['Elegant', 'Rustic', 'Modern', 'Bohemian', 'Traditional', 'Minimalist'];
  final Set<String> _selectedStyles = {};

  // AI plan results for step 4
  WeddingPlanResult? _aiPlanResult;
  bool _aiPlanLoading = false;
  String? _aiPlanError;

  static const _stepLabels = [
    "LET'S PLAN YOUR DAY",
    'YOUR WEDDING DATE',
    'STYLE & PREFERENCES',
    'FINAL DETAILS',
    'YOUR WEDDING PLAN',
  ];

  static const _stepTitles = [
    "What's your total\nwedding budget?",
    "When's your\nbig day?",
    "What's your\nwedding style?",
    "Any special\nrequirements?",
    "Your AI-curated\nwedding plan",
  ];

  @override
  void dispose() {
    _budgetCtrl.dispose();
    _guestsCtrl.dispose();
    _locationCtrl.dispose();
    _customCategoryCtrl.dispose();
    super.dispose();
  }

  List<String> _activeCategories() {
    final fixed = _vendorCategories.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    final merged = [...fixed, ..._customCategories];
    return merged.isNotEmpty ? merged : _vendorCategories.keys.toList();
  }

  void _addCustomCategory() {
    final raw = _customCategoryCtrl.text.trim();
    if (raw.isEmpty) return;
    final exists = _vendorCategories.keys
            .any((c) => c.toLowerCase() == raw.toLowerCase()) ||
        _customCategories.any((c) => c.toLowerCase() == raw.toLowerCase());
    if (exists) {
      _customCategoryCtrl.clear();
      return;
    }
    setState(() {
      _customCategories.add(raw);
      _customCategoryCtrl.clear();
    });
  }

  void _removeCustomCategory(String category) {
    setState(() => _customCategories.remove(category));
  }

  void _next() {
    if (_step == 0) {
      ref.read(selectedServiceCategoriesProvider.notifier).state =
          _activeCategories();
      ref.read(wizardLocationProvider.notifier).state = _locationCtrl.text.trim();
    }
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    }
  }

  Future<void> _saveProfile() async {
    await ref.read(authProvider.notifier).updateCoupleProfile(
          selectedItems: _activeCategories(),
          budget: double.tryParse(
                  _budgetCtrl.text.replaceAll(',', '').replaceAll(' ', '')) ??
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
    unawaited(_saveProfile());
    final categories = _activeCategories();
    ref.read(selectedServiceCategoriesProvider.notifier).state = categories;
    ref.read(wizardLocationProvider.notifier).state = _locationCtrl.text.trim();
    ref.read(wizardStylesProvider.notifier).state = _selectedStyles.toList();
    ref.read(budgetClassProvider.notifier).state = switch (_weddingClass) {
      'Low class' => BudgetClass.budgetFriendly,
      'High class' => BudgetClass.highClass,
      _ => BudgetClass.flexible,
    };
    final totalBudget = double.tryParse(
            _budgetCtrl.text.replaceAll(',', '').replaceAll(' ', '')) ??
        0;
    ref.read(budgetProvider.notifier).loadBudget(
          total: totalBudget,
          currency: 'ZMW',
          serviceCategories: categories,
        );
    setState(() => _step++);
    _loadWeddingAiPlan(totalBudget, categories);
  }

  Future<void> _loadWeddingAiPlan(double totalBudget, List<String> categories) async {
    setState(() { _aiPlanLoading = true; _aiPlanError = null; });
    try {
      final result = await WeddingAiService.instance.generateWeddingPlan(
        totalBudget: totalBudget,
        currency: 'ZMW',
        weddingType: _weddingType,
        weddingClass: _weddingClass,
        guestCount: int.tryParse(_guestsCtrl.text) ?? 0,
        location: _locationCtrl.text.trim().isEmpty ? 'Zambia' : _locationCtrl.text.trim(),
        weddingDate: _weddingDate,
        styles: _selectedStyles.toList(),
        categories: categories,
        topVendorNames: const {},
      );
      if (mounted) setState(() { _aiPlanResult = result; _aiPlanLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _aiPlanError = e.toString(); _aiPlanLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Column(
          children: [
            WizardHeader(
              step: _step,
              totalSteps: _totalSteps,
              stepLabel: _stepLabels[_step],
              stepTitle: _stepTitles[_step],
              onBack: _step > 0 ? () => setState(() => _step--) : null,
            ),
            Expanded(
              child: SingleChildScrollView(
                key: ValueKey(_step),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: _buildStep(),
                  ),
                ),
              ),
            ),
          ],
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
        return _buildDetailsStep();
      case 4:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }

  // ── Step 0: Budget & basics ─────────────────────────────────────────────────

  Widget _buildBudgetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Budget input
        WizardSectionLabel(icon: Icons.credit_card_outlined, label: 'Total wedding budget'),
        const SizedBox(height: 10),
        _BudgetField(controller: _budgetCtrl),
        const SizedBox(height: 8),
        Text(
          'This helps WedPilot match vendors within your range — you can adjust anytime.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),

        // Wedding type
        WizardSectionLabel(icon: Icons.favorite_border_rounded, label: 'Type of wedding'),
        const SizedBox(height: 10),
        _TypePills(
          options: const ['White wedding', 'Traditional', 'Both'],
          selected: _weddingType,
          onChanged: (v) => setState(() => _weddingType = v),
        ),
        const SizedBox(height: 24),

        // Guest count
        WizardSectionLabel(icon: Icons.people_outline_rounded, label: 'Number of guests'),
        const SizedBox(height: 10),
        _PlanField(
          controller: _guestsCtrl,
          hint: '150',
          inputType: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 24),

        // Location
        WizardSectionLabel(icon: Icons.location_on_outlined, label: 'Wedding location'),
        const SizedBox(height: 10),
        _PlanField(
          controller: _locationCtrl,
          hint: 'Ndola, Copperbelt',
          inputType: TextInputType.text,
        ),
        const SizedBox(height: 24),

        // Wedding class
        WizardSectionLabel(icon: Icons.credit_card_outlined, label: 'Choose your wedding class'),
        const SizedBox(height: 10),
        _WeddingClassCards(
          selected: _weddingClass,
          onChanged: (v) => setState(() => _weddingClass = v),
        ),
        const SizedBox(height: 24),

        // Vendor categories
        WizardSectionLabel(icon: Icons.grid_view_outlined, label: 'Vendors you\'ll need'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _vendorCategories.keys.map((cat) {
            final selected = _vendorCategories[cat]!;
            return GestureDetector(
              onTap: () => setState(() => _vendorCategories[cat] = !selected),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.amber.withAlpha(30)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.amber : AppColors.divider,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected
                        ? AppColors.amber
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_customCategories.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _customCategories.map((cat) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.forestGreen, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cat,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _removeCustomCategory(cat),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: AppColors.forestGreen),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _customCategoryCtrl,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addCustomCategory(),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Add another vendor type, e.g. Hair & Makeup',
                  hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _addCustomCategory,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.forestGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Add as many vendor types as you need — WedPilot AI will search and rank the best match for each.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        WizardContinueButton(onPressed: _next, label: 'Continue'),
      ],
    );
  }

  // ── Step 1: Date ────────────────────────────────────────────────────────────

  Widget _buildDateStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WizardSectionLabel(icon: Icons.calendar_today_outlined, label: 'Select your wedding date'),
        const SizedBox(height: 16),
        GestureDetector(
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
              color: AppColors.surface,
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
                  Icons.calendar_month_rounded,
                  color: _weddingDate != null
                      ? AppColors.forestGreen
                      : AppColors.textHint,
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
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        WizardContinueButton(onPressed: _next, label: 'Continue'),
      ],
    );
  }

  // ── Step 2: Style ───────────────────────────────────────────────────────────

  Widget _buildStyleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pick the vibe that describes your dream wedding.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _styleOptions.map((style) {
            final selected = _selectedStyles.contains(style);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) {
                  _selectedStyles.remove(style);
                } else {
                  _selectedStyles.add(style);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.forestGreen : AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: selected ? AppColors.forestGreen : AppColors.divider,
                  ),
                ),
                child: Text(
                  style,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        WizardContinueButton(onPressed: _next, label: 'Continue'),
      ],
    );
  }

  // ── Step 3: Details ─────────────────────────────────────────────────────────

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anything else WedPilot should know when matching vendors for you?',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        TextFormField(
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'e.g. We prefer garden settings, need halal catering options...',
            hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 32),
        WizardContinueButton(onPressed: _createPlan, label: 'Create our wedding plan'),
      ],
    );
  }

  // ── Step 4: AI-curated review ───────────────────────────────────────────────

  Widget _buildReviewStep() {
    final aiAsync = ref.watch(aiRecommendedVendorsProvider);
    final customVendors = ref.watch(customVendorsProvider);
    final budgetState = ref.watch(budgetProvider);
    final pdfAsync = ref.watch(weddingPlanPdfBytesProvider);
    final categories = _activeCategories();

    final budget = _budgetCtrl.text.isNotEmpty ? 'ZMW ${_budgetCtrl.text}' : 'Not set';
    final guests = _guestsCtrl.text.isNotEmpty ? '${_guestsCtrl.text} guests' : 'Not set';
    final location = _locationCtrl.text.isNotEmpty ? _locationCtrl.text : 'Not set';
    final dateStr = _weddingDate != null
        ? '${_weddingDate!.day} ${_month(_weddingDate!)} ${_weddingDate!.year}'
        : 'Not set';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── AI Plan Summary ──────────────────────────────────────────────────
        _AiPlanSummaryCard(
          loading: _aiPlanLoading,
          result: _aiPlanResult,
          error: _aiPlanError,
          categories: categories,
        ),
        const SizedBox(height: 20),

        // ── Wedding details recap ───────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              _SummaryRow(label: 'Budget', value: budget),
              _SummaryRow(label: 'Wedding type', value: _weddingType),
              _SummaryRow(label: 'Wedding class', value: _weddingClass),
              _SummaryRow(label: 'Guests', value: guests),
              _SummaryRow(label: 'Location', value: location),
              _SummaryRow(label: 'Date', value: dateStr),
              _SummaryRow(
                  label: 'Vendors needed', value: categories.join(', '), isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 24),
        WizardSectionLabel(icon: Icons.auto_awesome_rounded, label: 'AI-matched vendors'),
        const SizedBox(height: 4),
        Text(
          'WedPilot AI checks availability and ranks every vendor near you to pick the best match for each category.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        aiAsync.when(
          loading: () => const _AiRankingCard(),
          error: (e, st) => Text(
            "Couldn't reach WedPilot AI right now. Add vendors yourself below.",
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          data: (matches) {
            final bestByCategory = <String, VendorMatch>{};
            for (final m in matches) {
              if (m.rankInCategory == 1) bestByCategory[m.vendor.category] = m;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final category in categories) ...[
                  WizardSectionLabel(icon: categoryIcon(category), label: category),
                  const SizedBox(height: 10),
                  if (bestByCategory[category] != null)
                    _PlanVendorCard(
                      match: bestByCategory[category],
                      overrideReasoning: _aiPlanResult?.vendorReasonings[category],
                    )
                  else
                    Text(
                      'No available $category vendors matched yet — add one yourself below.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  for (final v in customVendors.where((v) => v.category == category)) ...[
                    const SizedBox(height: 10),
                    _PlanVendorCard(
                      vendor: v,
                      onRemove: () => ref.read(customVendorsProvider.notifier).remove(v.id),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _AddCustomVendorSheet(category: category),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add your own vendor'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.forestGreen,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ],
            );
          },
        ),
        if (budgetState.hasData) ...[
          const SizedBox(height: 10),
          WizardSectionLabel(icon: Icons.pie_chart_outline_rounded, label: 'Budget breakdown'),
          const SizedBox(height: 12),
          _BudgetBreakdownCard(budget: budgetState.data!),
          const SizedBox(height: 24),
        ],
        pdfAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(color: AppColors.forestGreen)),
          ),
          error: (e, st) => Text(
            'Could not prepare your plan document. Please try again.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          data: (bytes) => WedButton(
            label: 'Download PDF',
            icon: Icons.download_rounded,
            variant: WedButtonVariant.secondary,
            onPressed: () => Printing.layoutPdf(
              onLayout: (_) async => bytes,
              name: 'wedpilot-wedding-plan.pdf',
            ),
          ),
        ),
        const SizedBox(height: 16),
        WizardContinueButton(
          onPressed: () => context.go('/couple/dashboard'),
          label: 'Go to Dashboard',
        ),
      ],
    );
  }

  String _month(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
      return Icons.location_city_rounded;
    case 'Catering':
      return Icons.restaurant_rounded;
    case 'Photography':
      return Icons.camera_alt_rounded;
    case 'Decor & flowers':
      return Icons.local_florist_rounded;
    case 'DJ & MC':
      return Icons.music_note_rounded;
    case 'Transport':
      return Icons.directions_car_rounded;
    case 'Wedding attire':
      return Icons.checkroom_rounded;
    case 'Cake & sweets':
      return Icons.cake_rounded;
    default:
      return Icons.storefront_rounded;
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
                child: const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.forestGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'WedPilot AI is ranking the best vendors for your plan — checking '
                  'availability, reputation, and value for each category…',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
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

// ── Plan vendor card — AI pick or couple-added, with contact details ───────

class _PlanVendorCard extends StatelessWidget {
  final VendorMatch? match;
  final VendorProfile? vendor;
  final VoidCallback? onRemove;
  final String? overrideReasoning;

  const _PlanVendorCard({this.match, this.vendor, this.onRemove, this.overrideReasoning})
      : assert(match != null || vendor != null);

  VendorProfile get _vendor => match?.vendor ?? vendor!;

  @override
  Widget build(BuildContext context) {
    final v = _vendor;
    final isCustom = vendor != null;
    final servicesText = v.services.isNotEmpty
        ? v.services.map((s) => s.title).join(', ')
        : (v.description ?? '');
    final priceText = v.priceMax > 0
        ? '${fmtCurrency(v.priceMin)} – ${fmtCurrency(v.priceMax)}'
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  v.businessName,
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _Badge(
                label: isCustom ? 'Added by you' : 'AI top pick',
                color: isCustom ? AppColors.amber : AppColors.success,
              ),
              if (isCustom && onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.textHint),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (servicesText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              servicesText,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
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
                _ContactChip(icon: Icons.location_on_outlined, text: v.location!),
              if ((v.phone ?? '').isNotEmpty)
                _ContactChip(
                  icon: Icons.call_outlined,
                  text: v.phone!,
                  onTap: () => launchUrl(Uri.parse('tel:${v.phone}')),
                ),
              if (priceText != null)
                _ContactChip(icon: Icons.sell_outlined, text: priceText),
            ],
          ),
          if ((overrideReasoning ?? match?.reasoning) != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.amber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    overrideReasoning ?? match!.reasoning!,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

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
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      ],
    );
    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }
}

// ── Budget breakdown summary ────────────────────────────────────────────────

class _BudgetBreakdownCard extends StatelessWidget {
  final Budget budget;
  const _BudgetBreakdownCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final c in budget.categories)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text(c.categoryIcon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.categoryName,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    fmtCurrency(c.allocatedAmount, symbol: budget.currency),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text('Total budget',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  fmtCurrency(budget.totalAmount, symbol: budget.currency),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.forestGreen,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Add custom vendor sheet ─────────────────────────────────────────────────

class _AddCustomVendorSheet extends ConsumerStatefulWidget {
  final String category;
  const _AddCustomVendorSheet({required this.category});

  @override
  ConsumerState<_AddCustomVendorSheet> createState() => _AddCustomVendorSheetState();
}

class _AddCustomVendorSheetState extends ConsumerState<_AddCustomVendorSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty) {
      showWedSnackBar(context, 'Enter a business name to add this vendor', type: SnackType.warning);
      return;
    }
    ref.read(customVendorsProvider.notifier).add(
          businessName: _nameCtrl.text.trim(),
          category: widget.category,
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add a ${widget.category} vendor', style: AppTextStyles.titleLarge),
              const SizedBox(height: 16),
              WedTextField(
                label: 'Business name',
                hint: 'e.g. Aunt Grace Catering',
                controller: _nameCtrl,
              ),
              const SizedBox(height: 12),
              WedTextField(
                label: 'Phone (optional)',
                hint: '+260 ...',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              WedTextField(
                label: 'Location (optional)',
                hint: 'e.g. Ndola, Copperbelt',
                controller: _locationCtrl,
              ),
              const SizedBox(height: 12),
              WedTextField(
                label: 'Notes (optional)',
                hint: 'Anything else worth remembering',
                controller: _notesCtrl,
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              WedButton(
                label: 'Add vendor',
                variant: WedButtonVariant.primaryDark,
                onPressed: _submit,
              ),
            ],
          ),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.divider)),
            ),
            child: Text(
              'ZMW',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,]'))],
              style: AppTextStyles.displaySmall.copyWith(
                color: AppColors.textPrimary,
                fontSize: 20,
              ),
              decoration: InputDecoration(
                hintText: '85,000',
                hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
        ],
      ),
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
    return TextField(
      controller: controller,
      keyboardType: inputType,
      inputFormatters: formatters,
      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      ),
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
            padding: EdgeInsets.only(
              right: opt != options.last ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => onChanged(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.forestGreen : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.forestGreen : AppColors.divider,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
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
      ('Flexible', 'Mix & match', Icons.trending_up_rounded),
      ('High class', 'Premium only', Icons.star_outline_rounded),
    ];
    return Row(
      children: classes.map((c) {
        final (label, subtitle, icon) = c;
        final isSelected = selected == label;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: label != classes.last.$1 ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () => onChanged(label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.amber.withAlpha(30) : AppColors.surface,
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
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? AppColors.amber : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _SummaryRow({required this.label, required this.value, this.isLast = false});

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
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }
}

// ── AI plan summary card ────────────────────────────────────────────────────

class _AiPlanSummaryCard extends StatelessWidget {
  final bool loading;
  final WeddingPlanResult? result;
  final String? error;
  final List<String> categories;

  const _AiPlanSummaryCard({
    required this.loading,
    required this.result,
    required this.error,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.forestGreen, Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.amber, size: 18),
              const SizedBox(width: 8),
              Text(
                'WedPilot AI',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.amber,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (loading) ...[
            const _AiPlanShimmerLines(),
          ] else if (error != null) ...[
            Text(
              'AI summary unavailable — check your API key in .env',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
            ),
          ] else if (result != null) ...[
            Text(
              result!.planSummary,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white,
                height: 1.55,
              ),
            ),
            if (result!.budgetAdvice.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'SUGGESTED BUDGET SPLIT',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.amber,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              ...result!.budgetAdvice.entries
                  .where((e) => categories.contains(e.key))
                  .map((e) => _BudgetAdviceRow(category: e.key, percent: e.value)),
            ],
          ],
        ],
      ),
    );
  }
}

class _BudgetAdviceRow extends StatelessWidget {
  final String category;
  final double percent;
  const _BudgetAdviceRow({required this.category, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category,
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
            ),
          ),
          Text(
            '${percent.round()}%',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 6,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.amber),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiPlanShimmerLines extends StatefulWidget {
  const _AiPlanShimmerLines();

  @override
  State<_AiPlanShimmerLines> createState() => _AiPlanShimmerLinesState();
}

class _AiPlanShimmerLinesState extends State<_AiPlanShimmerLines>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final opacity = 0.3 + _ctrl.value * 0.4;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _shimmerBar(opacity, 1.0),
            const SizedBox(height: 8),
            _shimmerBar(opacity, 0.85),
            const SizedBox(height: 8),
            _shimmerBar(opacity, 0.6),
          ],
        );
      },
    );
  }

  Widget _shimmerBar(double opacity, double widthFactor) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((opacity * 255).round()),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
