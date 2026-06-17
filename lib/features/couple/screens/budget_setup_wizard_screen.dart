import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/budget.dart';
import '../../../models/vendor_profile.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/vendor_provider.dart';

// ── Constants ──────────────────────────────────────────────────────────────

const List<String> _kServices = [
  'Venue', 'Catering', 'Photography', 'Decoration',
  'Entertainment', 'Videography', 'Cake', 'Transport',
];

// Display name → AppConstants allocation key
const Map<String, String> _kAllocKey = {
  'Decoration': 'Floristry',
  'Entertainment': 'Music',
};

const Map<String, String> _kIcon = {
  'Venue': '🏛️', 'Catering': '🍽️', 'Photography': '📷',
  'Decoration': '🎀', 'Entertainment': '🎤', 'Videography': '🎬',
  'Cake': '🎂', 'Transport': '🚗',
};

const Map<String, Color> _kColor = {
  'Venue': Color(0xFF6C63FF), 'Catering': Color(0xFFFF6B6B),
  'Photography': Color(0xFF4ECDC4), 'Decoration': Color(0xFFFFBE0B),
  'Entertainment': Color(0xFFFF006E), 'Videography': Color(0xFF8338EC),
  'Cake': Color(0xFFFB5607), 'Transport': Color(0xFF38B000),
};

const _kPlanLow = 'Low Budget Plan';
const _kPlanMedium = 'Medium Budget Plan';
const _kCurrency = 'K';

String _fmt(double v) => NumberFormat('#,##0').format(v.round());

// ── Wizard ─────────────────────────────────────────────────────────────────

class BudgetSetupWizardScreen extends ConsumerStatefulWidget {
  const BudgetSetupWizardScreen({super.key});

  @override
  ConsumerState<BudgetSetupWizardScreen> createState() =>
      _BudgetSetupWizardState();
}

class _BudgetSetupWizardState extends ConsumerState<BudgetSetupWizardScreen> {
  int _step = 0;

  // Step 0 — details
  final _budgetCtrl = TextEditingController(text: '50000');
  final _locationCtrl = TextEditingController(text: 'Lusaka');
  final _guestCtrl = TextEditingController(text: '100');
  String _weddingType = 'Traditional';
  DateTime _weddingDate = DateTime.now().add(const Duration(days: 180));

  // Step 1 — budget class
  BudgetClass _budgetClass = BudgetClass.flexible;

  // Step 2 — plans
  String _selectedPlan = _kPlanLow;

  // Step 2 — services
  final List<String> _selectedServices = [
    'Venue', 'Catering', 'Photography', 'Decoration', 'Entertainment',
  ];
  final List<BudgetCustomItem> _customItems = [];
  final _customNameCtrl = TextEditingController();
  final _customCostCtrl = TextEditingController();

  // Step 3 — generation
  bool _isGenerating = false;

  // Step 4 — recommendations
  bool _showAllRecs = false;

  @override
  void dispose() {
    _budgetCtrl.dispose();
    _locationCtrl.dispose();
    _guestCtrl.dispose();
    _customNameCtrl.dispose();
    _customCostCtrl.dispose();
    super.dispose();
  }

  // ── Derived values ────────────────────────────────────────────────────────

  double get _budgetAmount =>
      double.tryParse(_budgetCtrl.text.replaceAll(',', '')) ?? 50000;

  double get _customTotal =>
      _customItems.fold(0.0, (s, i) => s + i.amount);

  double get _selectedEstimate => _selectedServices.fold(0.0, (sum, svc) {
        final key = _kAllocKey[svc] ?? svc;
        return sum + _budgetAmount * (AppConstants.defaultBudgetAllocation[key] ?? 0.05);
      });

  double get _budgetLeft =>
      (_budgetAmount - _selectedEstimate - _customTotal).clamp(0.0, double.infinity);

  /// Local preview allocation — shown in step 3 before tapping "Generate".
  List<({String name, String icon, double amount})> get _preview {
    final keys = _selectedServices.map((s) => _kAllocKey[s] ?? s).toList();
    final weights = keys.map((k) => AppConstants.defaultBudgetAllocation[k] ?? 0.05).toList();
    final wSum = weights.fold(0.0, (s, w) => s + w);
    final remaining = (_budgetAmount - _customTotal).clamp(0.0, _budgetAmount);
    final scale = wSum > 0 ? remaining / wSum : 0.0;
    return List.generate(_selectedServices.length, (i) => (
      name: _selectedServices[i],
      icon: _kIcon[_selectedServices[i]] ?? '💰',
      amount: weights[i] * scale,
    ));
  }

  static const List<String> _titles = [
    'Start Planning',
    'Select Budget Class',
    'Budget Plans Options',
    'Select Items & Services',
    'AI Generated Budget',
    'AI Recommendations',
    'Download Budget Report',
  ];

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _generateBudget() async {
    setState(() => _isGenerating = true);
    final mapped = _selectedServices.map((s) => _kAllocKey[s] ?? s).toList();
    ref.read(selectedServiceCategoriesProvider.notifier).state = mapped;
    ref.read(budgetClassProvider.notifier).state = _budgetClass;
    await ref.read(budgetProvider.notifier).loadMockBudget(
      _budgetAmount,
      _kCurrency,
      serviceCategories: mapped,
      customItems: _customItems,
    );
    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _step = 5;
    });
  }

  void _openAddCustomItem() {
    _customNameCtrl.clear();
    _customCostCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Add Custom Item', style: AppTextStyles.headlineMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ]),
            const SizedBox(height: 20),
            Text('Item Name:', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _customNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Estimated Cost:', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _customCostCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '$_kCurrency ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: _PrimaryButton(
                label: 'Add Item',
                onPressed: () {
                  final name = _customNameCtrl.text.trim();
                  final amount = double.tryParse(_customCostCtrl.text);
                  if (name.isEmpty || amount == null || amount <= 0) return;
                  setState(() {
                    _customItems.add(BudgetCustomItem(
                      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      amount: amount,
                    ));
                  });
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPdf() async {
    final budget = ref.read(budgetProvider).budget;
    if (budget == null) return;
    final recs = ref.read(aiRecommendedVendorsProvider).value?.map((m) => m.vendor).toList() ?? [];

    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => [
        pw.Header(level: 0, text: 'Wedding Budget Summary'),
        pw.SizedBox(height: 8),
        pw.Header(level: 1, text: 'Selected Items'),
        pw.TableHelper.fromTextArray(
          headers: ['Category', 'Allocated'],
          data: budget.categories
              .map((c) => [
                    c.categoryName,
                    '$_kCurrency ${_fmt(c.allocatedAmount)}',
                  ])
              .toList(),
        ),
        pw.SizedBox(height: 16),
        pw.Header(level: 1, text: 'Vendor Details'),
        pw.Column(
          children: recs
              .take(5)
              .map((v) => pw.Bullet(
                    text:
                        '${v.businessName} · ${v.category} · from $_kCurrency ${_fmt(v.priceMin)}',
                  ))
              .toList(),
        ),
        pw.SizedBox(height: 16),
        pw.Header(level: 1, text: 'Total Costs'),
        pw.Paragraph(
            text:
                'Total Budget: $_kCurrency ${_fmt(budget.totalAmount)}'),
        pw.Paragraph(
            text:
                'Total Allocated: $_kCurrency ${_fmt(budget.totalAllocated)}'),
        pw.Paragraph(
            text:
                'Remaining: $_kCurrency ${_fmt(budget.remainingBudget)}'),
      ],
    ));

    final bytes = await pdf.save();
    await Printing.sharePdf(
        bytes: bytes, filename: 'wedding-budget-summary.pdf');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final budgetState = ref.watch(budgetProvider);
    final aiRecs = ref.watch(aiRecommendedVendorsProvider);

    ref.listen<BudgetClass>(budgetClassProvider, (_, next) {
      if (_showAllRecs) setState(() => _showAllRecs = false);
    });

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: _step == 0
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => setState(() => _step--),
              ),
        title: Text(_titles[_step], style: AppTextStyles.headlineSmall),
      ),
      body: SafeArea(
        child: _buildStep(budgetState, aiRecs),
      ),
    );
  }

  Widget _buildStep(BudgetState budgetState, AsyncValue<List<VendorMatch>> aiRecs) {
    switch (_step) {
      case 0:
        return _DetailsStep(
          budgetCtrl: _budgetCtrl,
          locationCtrl: _locationCtrl,
          guestCtrl: _guestCtrl,
          weddingType: _weddingType,
          onWeddingTypeChange: (v) => setState(() => _weddingType = v),
          weddingDate: _weddingDate,
          onDateChanged: (d) => setState(() => _weddingDate = d),
          onNext: () => setState(() => _step = 1),
        );
      case 1:
        return _BudgetClassStep(
          selectedClass: _budgetClass,
          onSelect: (bc) {
            setState(() => _budgetClass = bc);
            ref.read(budgetClassProvider.notifier).state = bc;
          },
          onNext: () => setState(() => _step = 2),
        );
      case 2:
        return _PlansStep(
          selectedPlan: _selectedPlan,
          onSelectPlan: (plan) => setState(() {
            _selectedPlan = plan;
            _selectedServices.clear();
            _selectedServices.addAll(plan == _kPlanLow
                ? ['Venue', 'Catering', 'Photography', 'Decoration', 'Entertainment']
                : _kServices);
          }),
          onNext: () => setState(() => _step = 3),
        );
      case 3:
        return _ServicesStep(
          selectedServices: _selectedServices,
          onToggle: (s) => setState(() => _selectedServices.contains(s)
              ? _selectedServices.remove(s)
              : _selectedServices.add(s)),
          budgetLeft: _budgetLeft,
          customItems: _customItems,
          onAddCustomItem: _openAddCustomItem,
          onNext: () => setState(() => _step = 4),
        );
      case 4:
        return _AIBudgetStep(
          preview: _preview,
          budgetAmount: _budgetAmount,
          isGenerating: _isGenerating,
          onGenerate: _generateBudget,
        );
      case 5:
        return aiRecs.when(
          loading: () => const _RecsLoadingView(),
          error: (err, _) => const Center(child: Text('Could not load recommendations. Please try again.')),
          data: (matches) => _RecommendationsStep(
            matches: matches,
            budgetAmount: _budgetAmount,
            showAll: _showAllRecs,
            onShowMore: () => setState(() => _showAllRecs = true),
            onNext: () => setState(() => _step = 6),
          ),
        );
      case 6:
        return _DownloadReportStep(
          budgetState: budgetState,
          recs: aiRecs.value?.map((m) => m.vendor).toList() ?? [],
          onDownload: _downloadPdf,
          onFinish: () => context.go('/couple/budget'),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Step 0: Enter Budget Details ───────────────────────────────────────────

class _DetailsStep extends StatelessWidget {
  final TextEditingController budgetCtrl;
  final TextEditingController locationCtrl;
  final TextEditingController guestCtrl;
  final String weddingType;
  final ValueChanged<String> onWeddingTypeChange;
  final DateTime weddingDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onNext;

  const _DetailsStep({
    required this.budgetCtrl,
    required this.locationCtrl,
    required this.guestCtrl,
    required this.weddingType,
    required this.onWeddingTypeChange,
    required this.weddingDate,
    required this.onDateChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enter Your Wedding Budget:',
              style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          TextField(
            controller: budgetCtrl,
            keyboardType: TextInputType.number,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              prefixText: '$_kCurrency ',
              prefixStyle: AppTextStyles.bodyLarge,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(height: 20),
          Text('Type of Wedding:', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: weddingType,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
            items: ['Traditional', 'White Wedding', 'Custom']
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => onWeddingTypeChange(v!),
          ),
          const SizedBox(height: 20),
          Text('Location:', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          TextField(
            controller: locationCtrl,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(height: 20),
          Text('Number of Guests:', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          TextField(
            controller: guestCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(height: 20),
          Text('Preferred Wedding Date:', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: weddingDate,
                firstDate: DateTime.now(),
                lastDate:
                    DateTime.now().add(const Duration(days: 3650)),
              );
              if (picked != null) onDateChanged(picked);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat.yMMMMd().format(weddingDate),
                    style: AppTextStyles.bodyMedium,
                  ),
                  Icon(Icons.calendar_today_outlined,
                      size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 36),
          _PrimaryButton(label: 'NEXT', onPressed: onNext),
        ],
      ),
    );
  }
}

// ── Step 1: Budget Plans Options ───────────────────────────────────────────

class _PlansStep extends StatelessWidget {
  final String selectedPlan;
  final ValueChanged<String> onSelectPlan;
  final VoidCallback onNext;

  const _PlansStep({
    required this.selectedPlan,
    required this.onSelectPlan,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _PlanCard(
                title: 'Low\nBudget\nPlan',
                price: '$_kCurrency 50,000',
                isSelected: selectedPlan == _kPlanLow,
                onTap: () => onSelectPlan(_kPlanLow),
              ),
              const SizedBox(width: 14),
              _PlanCard(
                title: 'Medium\nBudget Plan',
                price: '$_kCurrency 100,000+',
                isSelected: selectedPlan == _kPlanMedium,
                onTap: () => onSelectPlan(_kPlanMedium),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Choose Plans',
            style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          _PrimaryButton(label: 'generate', onPressed: onNext),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondary : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.secondary : Theme.of(context).colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withAlpha(40),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                price,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 2: Select Items & Services ────────────────────────────────────────

class _ServicesStep extends StatelessWidget {
  final List<String> selectedServices;
  final void Function(String) onToggle;
  final double budgetLeft;
  final List<BudgetCustomItem> customItems;
  final VoidCallback onAddCustomItem;
  final VoidCallback onNext;

  const _ServicesStep({
    required this.selectedServices,
    required this.onToggle,
    required this.budgetLeft,
    required this.customItems,
    required this.onAddCustomItem,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              ..._kServices.map((svc) {
                final selected = selectedServices.contains(svc);
                return CheckboxListTile(
                  value: selected,
                  onChanged: (_) => onToggle(svc),
                  title: Text(svc, style: AppTextStyles.bodyMedium),
                  secondary: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (_kColor[svc] ?? AppColors.secondary)
                          .withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _kIcon[svc] ?? '💰',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  activeColor: AppColors.secondary,
                  controlAffinity: ListTileControlAffinity.trailing,
                  contentPadding: EdgeInsets.zero,
                );
              }),
              if (customItems.isNotEmpty) ...[
                const Divider(height: 24),
                Text('Custom Items', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 8),
                ...customItems.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.receipt_outlined, size: 20),
                    title: Text(item.name,
                        style: AppTextStyles.bodyMedium),
                    trailing: Text(
                      '$_kCurrency ${_fmt(item.amount)}',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.secondary),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onAddCustomItem,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add Custom Item'),
              ),
            ],
          ),
        ),

        // Budget Left banner
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Budget Left:',
                    style: AppTextStyles.bodyMedium),
                Text(
                  '$_kCurrency ${_fmt(budgetLeft)}',
                  style: AppTextStyles.headlineSmall
                      .copyWith(color: AppColors.secondary),
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: _PrimaryButton(
            label: 'SELECTED Items',
            onPressed: selectedServices.isEmpty ? null : onNext,
          ),
        ),
      ],
    );
  }
}

// ── Step 3: AI Generated Budget ────────────────────────────────────────────

class _AIBudgetStep extends StatelessWidget {
  final List<({String name, String icon, double amount})> preview;
  final double budgetAmount;
  final bool isGenerating;
  final VoidCallback onGenerate;

  const _AIBudgetStep({
    required this.preview,
    required this.budgetAmount,
    required this.isGenerating,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Total budget header
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Text(
            'Total Budget: $_kCurrency ${_fmt(budgetAmount)}',
            style: AppTextStyles.headlineMedium
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const Divider(height: 1),

        // Category preview list
        Expanded(
          child: ListView.separated(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: preview.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 44),
            itemBuilder: (_, i) {
              final item = preview[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color:
                            (_kColor[item.name] ?? AppColors.secondary)
                                .withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(item.icon,
                            style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(item.name,
                          style: AppTextStyles.bodyMedium),
                    ),
                    Text(
                      '$_kCurrency ${_fmt(item.amount)}',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.secondary),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.check_box,
                        color: AppColors.secondary, size: 20),
                  ],
                ),
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(20),
          child: _PrimaryButton(
            label: isGenerating ? 'Generating...' : 'GENERATE THE BUDGET',
            isLoading: isGenerating,
            onPressed: isGenerating ? null : onGenerate,
          ),
        ),
      ],
    );
  }
}

// ── Step 5: AI Recommendations ─────────────────────────────────────────────

class _RecommendationsStep extends ConsumerWidget {
  final List<VendorMatch> matches;
  final double budgetAmount;
  final bool showAll;
  final VoidCallback onShowMore;
  final VoidCallback onNext;

  const _RecommendationsStep({
    required this.matches,
    required this.budgetAmount,
    required this.showAll,
    required this.onShowMore,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final currentClass = ref.watch(budgetClassProvider);
    final visible = showAll ? matches : matches.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Budget class switcher ─────────────────────────────────────────────
        Container(
          color: cs.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Budget: $_kCurrency ${_fmt(budgetAmount)}',
                style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Row(
                children: BudgetClass.values.map((bc) {
                  final selected = bc == currentClass;
                  final accent = _budgetClassColor(bc);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => ref.read(budgetClassProvider.notifier).state = bc,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? accent : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                          border: selected ? null : Border.all(color: cs.outlineVariant),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(bc.icon, style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 2),
                            Text(
                              bc.displayName,
                              style: AppTextStyles.caption.copyWith(
                                color: selected ? Colors.white : cs.onSurface.withValues(alpha: 0.7),
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              Text(
                currentClass.subtitle,
                style: AppTextStyles.caption.copyWith(color: cs.onSurface.withValues(alpha: 0.55)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Vendor list ───────────────────────────────────────────────────────
        Expanded(
          child: matches.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(currentClass.icon, style: const TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text('No vendors match this tier yet',
                            style: AppTextStyles.headlineSmall, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text('Try switching to Flexible mode to see all available vendors.',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.6)),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    ...visible.map((m) => _VendorRecommendationCard(match: m)),
                    if (!showAll && matches.length > 5) ...[
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: onShowMore,
                        child: Text(
                          'SHOW MORE RECOMMENDATIONS ∨',
                          style: AppTextStyles.labelLarge.copyWith(color: AppColors.secondary),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: _PrimaryButton(label: 'Continue to Download Report', onPressed: onNext),
        ),
      ],
    );
  }

  static Color _budgetClassColor(BudgetClass bc) => switch (bc) {
    BudgetClass.highClass      => AppColors.goldPremium,
    BudgetClass.flexible       => AppColors.secondary,
    BudgetClass.budgetFriendly => AppColors.budgetGreen,
  };
}

class _VendorRecommendationCard extends StatelessWidget {
  final VendorMatch match;

  const _VendorRecommendationCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final vendor = match.vendor;
    final cs = Theme.of(context).colorScheme;
    final catColor = _kColor[vendor.category] ?? AppColors.secondary;

    // Tier badge config
    final (tierLabel, tierColor) = switch (vendor.priceTier) {
      VendorPriceTier.high => ('👑 Premium',  AppColors.goldPremium),
      VendorPriceTier.mid  => ('🔷 Mid-Range', AppColors.info),
      VendorPriceTier.low  => ('💚 Budget',    AppColors.budgetGreen),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Main row ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category icon + rank badge
                Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: catColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(_kIcon[vendor.category] ?? '🏢',
                            style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                    if (match.rankInCategory == 1)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('#1', style: AppTextStyles.caption.copyWith(
                              color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(vendor.businessName,
                                style: AppTextStyles.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Text('$_kCurrency ${_fmt(vendor.priceMin)}',
                              style: AppTextStyles.titleMedium
                                  .copyWith(color: AppColors.secondary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Description
                      if (vendor.description != null)
                        Text(
                          vendor.description!,
                          style: AppTextStyles.caption.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.6)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 6),
                      // Tier badge + location
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: tierColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(tierLabel,
                                style: AppTextStyles.caption.copyWith(
                                    color: tierColor, fontWeight: FontWeight.w600)),
                          ),
                          if (vendor.location != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(vendor.location!,
                                  style: AppTextStyles.caption.copyWith(
                                      color: cs.onSurface.withValues(alpha: 0.5)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── AI Reasoning ──────────────────────────────────────────────────────
          if (match.reasoning != null)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, size: 13, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      match.reasoning!,
                      style: AppTextStyles.caption.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.7)),
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

// ── Loading view shown while AI re-ranks after budget class switch ──────────

class _RecsLoadingView extends StatelessWidget {
  const _RecsLoadingView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 48, color: AppColors.secondary),
          const SizedBox(height: 20),
          Text('AI is ranking vendors…', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text('Applying your budget class preferences',
              style: AppTextStyles.bodySmall.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 24),
          const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary)),
        ],
      ),
    );
  }
}

// ── Step 5: Download Budget Report ─────────────────────────────────────────

class _DownloadReportStep extends StatelessWidget {
  final BudgetState budgetState;
  final List<VendorProfile> recs;
  final VoidCallback onDownload;
  final VoidCallback onFinish;

  const _DownloadReportStep({
    required this.budgetState,
    required this.recs,
    required this.onDownload,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final budget = budgetState.budget;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary header banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.secondary.withAlpha(40)),
            ),
            child: Column(
              children: [
                Text(
                  'WEDDING BUDGET SUMMARY',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.secondary,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (budget != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Total: $_kCurrency ${_fmt(budget.totalAmount)}',
                    style: AppTextStyles.displaySmall
                        .copyWith(color: AppColors.secondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Selected Items section
          _SectionHeader(title: 'Selected Items'),
          const SizedBox(height: 12),
          if (budget != null)
            ...budget.categories.map(
              (cat) => _ReportRow(
                leading: cat.categoryIcon,
                label: cat.categoryName,
                value: '$_kCurrency ${_fmt(cat.allocatedAmount)}',
              ),
            )
          else
            _EmptySection(label: 'No budget generated yet'),
          const SizedBox(height: 24),

          // Vendor Details section
          _SectionHeader(title: 'Vendor Details'),
          const SizedBox(height: 12),
          if (recs.isNotEmpty)
            ...recs.take(4).map(
                  (v) => _ReportRow(
                    leading:
                        _kIcon[v.category] ?? '🏢',
                    label: v.businessName,
                    value: 'from $_kCurrency ${_fmt(v.priceMin)}',
                    sublabel: v.location,
                  ),
                )
          else
            _EmptySection(label: 'No vendor recommendations'),
          const SizedBox(height: 24),

          // Total Costs section
          _SectionHeader(title: 'Total Costs'),
          const SizedBox(height: 12),
          if (budget != null) ...[
            _ReportRow(
              leading: '💰',
              label: 'Total Budget',
              value: '$_kCurrency ${_fmt(budget.totalAmount)}',
              bold: true,
            ),
            _ReportRow(
              leading: '✅',
              label: 'Allocated',
              value: '$_kCurrency ${_fmt(budget.totalAllocated)}',
            ),
            _ReportRow(
              leading: '💳',
              label: 'Spent',
              value: '$_kCurrency ${_fmt(budget.totalSpent)}',
            ),
            _ReportRow(
              leading: '🛡️',
              label: 'Remaining',
              value: '$_kCurrency ${_fmt(budget.remainingBudget)}',
              bold: true,
              valueColor: AppColors.budgetGreen,
            ),
          ] else
            _EmptySection(label: 'Generate a budget to see totals'),
          const SizedBox(height: 36),

          _PrimaryButton(label: 'DOWNLOAD PDF', onPressed: onDownload),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onFinish,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('View Budget Overview',
                style: AppTextStyles.buttonText
                    .copyWith(color: Theme.of(context).colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(title,
          style: AppTextStyles.labelLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String leading;
  final String label;
  final String value;
  final String? sublabel;
  final bool bold;
  final Color? valueColor;

  const _ReportRow({
    required this.leading,
    required this.label,
    required this.value,
    this.sublabel,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = bold
        ? AppTextStyles.titleMedium
        : AppTextStyles.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(leading, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                if (sublabel != null)
                  Text(sublabel!,
                      style: AppTextStyles.caption.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ),
          Text(
            value,
            style: labelStyle.copyWith(
              color: valueColor ?? AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String label;
  const _EmptySection({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(label,
          style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
    );
  }
}

// ── Step 1: Budget Class Selection ─────────────────────────────────────────

class _BudgetClassStep extends StatelessWidget {
  final BudgetClass selectedClass;
  final ValueChanged<BudgetClass> onSelect;
  final VoidCallback onNext;

  const _BudgetClassStep({
    required this.selectedClass,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How would you describe your wedding budget?',
                  style: AppTextStyles.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Our AI will tailor every vendor recommendation to match your budget class.',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 20),
                ...BudgetClass.values.map(
                  (bc) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _BudgetClassCard(
                      budgetClass: bc,
                      isSelected: selectedClass == bc,
                      onTap: () => onSelect(bc),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: _PrimaryButton(label: 'NEXT', onPressed: onNext),
        ),
      ],
    );
  }
}

class _BudgetClassCard extends StatelessWidget {
  final BudgetClass budgetClass;
  final bool isSelected;
  final VoidCallback onTap;

  const _BudgetClassCard({
    required this.budgetClass,
    required this.isSelected,
    required this.onTap,
  });

  static Color _accentFor(BudgetClass bc) => switch (bc) {
    BudgetClass.highClass      => AppColors.goldPremium,
    BudgetClass.flexible       => AppColors.secondary,
    BudgetClass.budgetFriendly => AppColors.budgetGreen,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = _accentFor(budgetClass);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? accent.withAlpha(18) : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accent : cs.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected ? accent.withAlpha(30) : cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(budgetClass.icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(budgetClass.displayName,
                            style: AppTextStyles.titleMedium.copyWith(
                                color: isSelected ? accent : cs.onSurface)),
                      ),
                      if (budgetClass == BudgetClass.flexible)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Recommended',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.secondary, fontWeight: FontWeight.w700)),
                        ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: accent, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(budgetClass.description,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.65))),
                  const SizedBox(height: 10),
                  // Feature bullets
                  ...budgetClass.features.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check, size: 13, color: accent),
                          const SizedBox(width: 6),
                          Text(f,
                              style: AppTextStyles.caption.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.75))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared primary button ──────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          disabledBackgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 13),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        onPressed: onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(label,
                style: AppTextStyles.buttonText
                    .copyWith(color: Colors.white)),
      ),
    );
  }
}
