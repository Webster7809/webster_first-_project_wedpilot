import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/dash_progress_bar.dart';

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

  // Step 1 — Date
  DateTime? _weddingDate;

  // Step 2 — Style
  final _styleOptions = ['Elegant', 'Rustic', 'Modern', 'Bohemian', 'Traditional', 'Minimalist'];
  final Set<String> _selectedStyles = {};

  static const _stepLabels = [
    "LET'S PLAN YOUR DAY",
    'YOUR WEDDING DATE',
    'STYLE & PREFERENCES',
    'FINAL DETAILS',
    "YOU'RE ALL SET",
  ];

  static const _stepTitles = [
    "What's your total\nwedding budget?",
    "When's your\nbig day?",
    "What's your\nwedding style?",
    "Any special\nrequirements?",
    "Review your\nwedding plan",
  ];

  @override
  void dispose() {
    _budgetCtrl.dispose();
    _guestsCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _finish() {
    final selectedItems = _vendorCategories.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    ref.read(authProvider.notifier).updateCoupleProfile(
          selectedItems: selectedItems,
          budget: double.tryParse(
                  _budgetCtrl.text.replaceAll(',', '').replaceAll(' ', '')) ??
              0,
          weddingStyle: _weddingType,
          weddingClass: _weddingClass,
          guestCount: int.tryParse(_guestsCtrl.text) ?? 0,
          location: _locationCtrl.text.trim(),
        );
    context.go('/couple/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Column(
          children: [
            _WizardHeader(
              step: _step,
              totalSteps: _totalSteps,
              stepLabel: _stepLabels[_step],
              stepTitle: _stepTitles[_step],
              onBack: _step > 0 ? () => setState(() => _step--) : null,
            ),
            Expanded(
              child: SingleChildScrollView(
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
        return _buildConfirmStep();
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
        _SectionLabel(icon: Icons.credit_card_outlined, label: 'Total wedding budget'),
        const SizedBox(height: 10),
        _BudgetField(controller: _budgetCtrl),
        const SizedBox(height: 8),
        Text(
          'This helps WedPilot match vendors within your range — you can adjust anytime.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),

        // Wedding type
        _SectionLabel(icon: Icons.favorite_border_rounded, label: 'Type of wedding'),
        const SizedBox(height: 10),
        _TypePills(
          options: const ['White wedding', 'Traditional', 'Both'],
          selected: _weddingType,
          onChanged: (v) => setState(() => _weddingType = v),
        ),
        const SizedBox(height: 24),

        // Guest count
        _SectionLabel(icon: Icons.people_outline_rounded, label: 'Number of guests'),
        const SizedBox(height: 10),
        _PlanField(
          controller: _guestsCtrl,
          hint: '150',
          inputType: TextInputType.number,
          formatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 24),

        // Location
        _SectionLabel(icon: Icons.location_on_outlined, label: 'Wedding location'),
        const SizedBox(height: 10),
        _PlanField(
          controller: _locationCtrl,
          hint: 'Ndola, Copperbelt',
          inputType: TextInputType.text,
        ),
        const SizedBox(height: 24),

        // Wedding class
        _SectionLabel(icon: Icons.credit_card_outlined, label: 'Choose your wedding class'),
        const SizedBox(height: 10),
        _WeddingClassCards(
          selected: _weddingClass,
          onChanged: (v) => setState(() => _weddingClass = v),
        ),
        const SizedBox(height: 24),

        // Vendor categories
        _SectionLabel(icon: Icons.grid_view_outlined, label: 'Vendors you\'ll need'),
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
        const SizedBox(height: 32),
        _ContinueButton(onTap: _next, label: 'Continue'),
      ],
    );
  }

  // ── Step 1: Date ────────────────────────────────────────────────────────────

  Widget _buildDateStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(icon: Icons.calendar_today_outlined, label: 'Select your wedding date'),
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
                Text(
                  _weddingDate != null
                      ? '${_weekday(_weddingDate!)}, ${_weddingDate!.day} ${_month(_weddingDate!)} ${_weddingDate!.year}'
                      : 'Tap to pick your date',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: _weddingDate != null
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        _ContinueButton(onTap: _next, label: 'Continue'),
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
        _ContinueButton(onTap: _next, label: 'Continue'),
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
        _ContinueButton(onTap: _next, label: 'Continue'),
      ],
    );
  }

  // ── Step 4: Confirm ─────────────────────────────────────────────────────────

  Widget _buildConfirmStep() {
    final budget = _budgetCtrl.text.isNotEmpty ? 'ZMW ${_budgetCtrl.text}' : 'Not set';
    final guests = _guestsCtrl.text.isNotEmpty ? '${_guestsCtrl.text} guests' : 'Not set';
    final location = _locationCtrl.text.isNotEmpty ? _locationCtrl.text : 'Not set';
    final dateStr = _weddingDate != null
        ? '${_weddingDate!.day} ${_month(_weddingDate!)} ${_weddingDate!.year}'
        : 'Not set';
    final categories = _vendorCategories.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              if (categories.isNotEmpty)
                _SummaryRow(label: 'Vendors needed', value: categories, isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _ContinueButton(onTap: _finish, label: 'Create our wedding plan'),
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

// ── Wizard header ─────────────────────────────────────────────────────────────

class _WizardHeader extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String stepLabel;
  final String stepTitle;
  final VoidCallback? onBack;

  const _WizardHeader({
    required this.step,
    required this.totalSteps,
    required this.stepLabel,
    required this.stepTitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.forestGreen,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (onBack != null)
                    GestureDetector(
                      onTap: onBack,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_left_rounded,
                            color: Colors.white, size: 22),
                      ),
                    )
                  else
                    const SizedBox(width: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'STEP ${step + 1} OF $totalSteps',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                stepLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amber,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                stepTitle,
                style: const TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 16),
              DashProgressBar(total: totalSteps, current: step),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.amber),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
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

// ── Continue button ───────────────────────────────────────────────────────────

class _ContinueButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const _ContinueButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
