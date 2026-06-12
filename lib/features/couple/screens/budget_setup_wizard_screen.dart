import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/budget.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/vendor_provider.dart';
import '../../../widgets/wed_button.dart';

class BudgetSetupWizardScreen extends ConsumerStatefulWidget {
  const BudgetSetupWizardScreen({super.key});

  @override
  ConsumerState<BudgetSetupWizardScreen> createState() => _BudgetSetupWizardScreenState();
}

class _BudgetSetupWizardScreenState extends ConsumerState<BudgetSetupWizardScreen> {
  int _step = 0;
  final _budgetCtrl = TextEditingController(text: '50000');
  final _locationCtrl = TextEditingController();
  final _customItemNameCtrl = TextEditingController();
  final _customItemCostCtrl = TextEditingController();
  String _currency = 'USD';
  String _weddingType = 'Traditional';
  String _selectedPlan = 'Low class';
  DateTime _weddingDate = DateTime.now().add(const Duration(days: 180));
  int _guestCount = 120;
  final List<String> _selectedServices = ['Venue', 'Catering', 'Photography', 'Floristry', 'Music'];
  final List<BudgetCustomItem> _customItems = [];
  bool _isGenerating = false;

  @override
  void dispose() {
    _budgetCtrl.dispose();
    _locationCtrl.dispose();
    _customItemNameCtrl.dispose();
    _customItemCostCtrl.dispose();
    super.dispose();
  }

  double get _budgetAmount =>
      double.tryParse(_budgetCtrl.text.replaceAll(',', '')) ?? 50000;

  double get _selectedServicesEstimate {
    return _selectedServices.fold(0.0, (sum, service) {
      final percentage = AppConstants.defaultBudgetAllocation[service] ?? 0.05;
      return sum + (_budgetAmount * percentage);
    });
  }

  double get _customItemsCost =>
      _customItems.fold(0.0, (sum, item) => sum + item.amount);

  double get _selectionRemaining =>
      (_budgetAmount - _selectedServicesEstimate - _customItemsCost).clamp(0.0, double.infinity);

  String get _budgetFriendlyPlan {
    if (_budgetAmount < 60000) return 'Low class';
    if (_budgetAmount < 120000) return 'High class';
    return 'Premium';
  }

  Future<void> _generateAllocation() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(seconds: 2));
    ref.read(selectedServiceCategoriesProvider.notifier).state = _selectedServices;
    await ref.read(budgetProvider.notifier).loadMockBudget(
          _budgetAmount,
          _currency,
          serviceCategories: _selectedServices,
          customItems: _customItems,
        );
    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _step = 3;
    });
  }

  void _addCustomItem() {
    final name = _customItemNameCtrl.text.trim();
    final amount = double.tryParse(_customItemCostCtrl.text);
    if (name.isEmpty || amount == null || amount <= 0) {
      return;
    }
    setState(() {
      _customItems.add(BudgetCustomItem(
        id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        amount: amount,
      ));
      _customItemNameCtrl.clear();
      _customItemCostCtrl.clear();
    });
  }

  void _toggleService(String service) {
    setState(() {
      if (_selectedServices.contains(service)) {
        _selectedServices.remove(service);
      } else {
        _selectedServices.add(service);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Budget Setup — Step ${_step + 1} of 4'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: List.generate(4, (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i <= _step ? AppColors.secondary : AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _step,
              children: [
                _DetailsStep(
                  budgetCtrl: _budgetCtrl,
                  currency: _currency,
                  onCurrencyChange: (value) => setState(() => _currency = value),
                  locationCtrl: _locationCtrl,
                  weddingType: _weddingType,
                  onWeddingTypeChange: (value) => setState(() => _weddingType = value),
                  guestCount: _guestCount,
                  onGuestCountChange: (value) => setState(() => _guestCount = value),
                  weddingDate: _weddingDate,
                  onDateChanged: (date) => setState(() => _weddingDate = date),
                ),
                _PlanSelectionStep(
                  budget: _budgetAmount,
                  selectedPlan: _selectedPlan,
                  budgetFriendlyPlan: _budgetFriendlyPlan,
                  onSelectPlan: (plan) => setState(() {
                    _selectedPlan = plan;
                    if (plan == 'Low class') {
                      _selectedServices
                        ..clear()
                        ..addAll(['Venue', 'Catering', 'Photography']);
                    } else if (plan == 'High class') {
                      _selectedServices
                        ..clear()
                        ..addAll(AppConstants.vendorCategories.take(8));
                    }
                  }),
                ),
                _ServiceSelectionStep(
                  selectedServices: _selectedServices,
                  onServiceToggle: _toggleService,
                  selectedEstimate: _selectedServicesEstimate,
                  customItems: _customItems,
                  customItemNameCtrl: _customItemNameCtrl,
                  customItemCostCtrl: _customItemCostCtrl,
                  onAddCustomItem: _addCustomItem,
                  remainingBudget: _selectionRemaining,
                  currency: _currency,
                ),
                _AllocationReviewStep(budgetState: ref.watch(budgetProvider)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (_step == 2)
                  WedButton(
                    label: _isGenerating ? 'AI is calculating...' : 'Generate AI Allocation ✨',
                    onPressed: _isGenerating ? null : _generateAllocation,
                    isLoading: _isGenerating,
                  )
                else if (_step == 3)
                  WedButton(
                    label: 'Accept & View Budget Overview',
                    onPressed: () => context.go('/couple/budget'),
                  )
                else
                  WedButton(
                    label: 'Next',
                    onPressed: () => setState(() => _step = (_step + 1).clamp(0, 3)),
                  ),
                if (_step > 0) ...[
                  const SizedBox(height: 8),
                  WedButton(
                    label: 'Back',
                    variant: WedButtonVariant.ghost,
                    onPressed: () => setState(() => _step = (_step - 1).clamp(0, 3)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsStep extends StatelessWidget {
  final TextEditingController budgetCtrl;
  final String currency;
  final ValueChanged<String> onCurrencyChange;
  final TextEditingController locationCtrl;
  final String weddingType;
  final ValueChanged<String> onWeddingTypeChange;
  final int guestCount;
  final ValueChanged<int> onGuestCountChange;
  final DateTime weddingDate;
  final ValueChanged<DateTime> onDateChanged;

  const _DetailsStep({
    required this.budgetCtrl,
    required this.currency,
    required this.onCurrencyChange,
    required this.locationCtrl,
    required this.weddingType,
    required this.onWeddingTypeChange,
    required this.guestCount,
    required this.onGuestCountChange,
    required this.weddingDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Wedding Basics', style: AppTextStyles.displaySmall),
          const SizedBox(height: 8),
          Text('Enter the details that shape your budget and vendor recommendations.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 28),
          DropdownButtonFormField<String>(
            initialValue: weddingType,
            decoration: InputDecoration(
              labelText: 'Wedding Type',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: ['Traditional', 'White Wedding', 'Custom']
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) => onWeddingTypeChange(value!),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: locationCtrl,
            decoration: InputDecoration(
              labelText: 'Location',
              hintText: 'City, venue or region',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: currency,
                  decoration: InputDecoration(
                    labelText: 'Currency',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['USD', 'EUR', 'GBP', 'CAD', 'AUD', 'NGN', 'KES', 'ZAR']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) => onCurrencyChange(value!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: budgetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Budget',
                    prefixText: '$currency ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Guest count: $guestCount', style: AppTextStyles.headlineSmall),
          Slider(
            value: guestCount.toDouble(),
            min: 20,
            max: 500,
            divisions: 48,
            label: '$guestCount guests',
            activeColor: AppColors.secondary,
            onChanged: (value) => onGuestCountChange(value.round()),
          ),
          const SizedBox(height: 18),
          Text('Wedding date', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: weddingDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (picked != null) onDateChanged(picked);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.divider),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat.yMMMMd().format(weddingDate), style: AppTextStyles.bodyMedium),
                  const Icon(Icons.calendar_today_outlined),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanSelectionStep extends StatelessWidget {
  final double budget;
  final String selectedPlan;
  final String budgetFriendlyPlan;
  final ValueChanged<String> onSelectPlan;

  const _PlanSelectionStep({
    required this.budget,
    required this.selectedPlan,
    required this.budgetFriendlyPlan,
    required this.onSelectPlan,
  });

  @override
  Widget build(BuildContext context) {
    final plans = [
      {'title': 'Low class', 'subtitle': 'Smart spending for a smaller celebration', 'estimate': 'K50,000'},
      {'title': 'High class', 'subtitle': 'Luxury planning with premium service', 'estimate': 'K100,000+'},
      {'title': 'Custom', 'subtitle': 'Tailor your own budget plan', 'estimate': 'Flexible'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose a budget plan', style: AppTextStyles.displaySmall),
          const SizedBox(height: 8),
          Text('Pick the plan that best matches your wedding vision.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: plans.map((plan) {
              final title = plan['title'] as String;
              final subtitle = plan['subtitle'] as String;
              final estimate = plan['estimate'] as String;
              final isSelected = selectedPlan == title;
              return GestureDetector(
                onTap: () => onSelectPlan(title),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.42,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.secondary.withValues(alpha: 0.15) : AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? AppColors.secondary : AppColors.divider,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.titleMedium),
                      const SizedBox(height: 6),
                      Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      Text(estimate, style: AppTextStyles.headlineSmall.copyWith(color: AppColors.secondary)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          Text('Recommended for you', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text('Based on your budget, the best fit is $budgetFriendlyPlan plan.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Text('Budget preview', style: AppTextStyles.labelLarge),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total available', style: AppTextStyles.caption),
                Text('\$${budget.toStringAsFixed(0)}', style: AppTextStyles.displaySmall.copyWith(color: AppColors.secondary)),
                const SizedBox(height: 10),
                Text('Plan details are based on your selected wedding goals.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceSelectionStep extends StatelessWidget {
  final List<String> selectedServices;
  final void Function(String) onServiceToggle;
  final double selectedEstimate;
  final List<BudgetCustomItem> customItems;
  final TextEditingController customItemNameCtrl;
  final TextEditingController customItemCostCtrl;
  final VoidCallback onAddCustomItem;
  final double remainingBudget;
  final String currency;

  const _ServiceSelectionStep({
    required this.selectedServices,
    required this.onServiceToggle,
    required this.selectedEstimate,
    required this.customItems,
    required this.customItemNameCtrl,
    required this.customItemCostCtrl,
    required this.onAddCustomItem,
    required this.remainingBudget,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select your wedding services', style: AppTextStyles.displaySmall),
          const SizedBox(height: 8),
          Text('Choose the services you want included in your wedding plan.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.vendorCategories.take(8).map((service) {
              final selected = selectedServices.contains(service);
              return FilterChip(
                label: Text(service),
                selected: selected,
                onSelected: (_) => onServiceToggle(service),
                selectedColor: AppColors.secondary.withValues(alpha: 0.20),
                checkmarkColor: AppColors.secondary,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Estimated service spend', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text('\$${selectedEstimate.toStringAsFixed(0)} estimated for selected services.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Remaining budget: $currency ${remainingBudget.toStringAsFixed(0)}',
              style: AppTextStyles.titleMedium.copyWith(color: remainingBudget > 0 ? AppColors.budgetGreen : AppColors.error)),
          const SizedBox(height: 24),
          Text('Add custom items', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          TextFormField(
            controller: customItemNameCtrl,
            decoration: InputDecoration(
              hintText: 'Item name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: customItemCostCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Estimated cost',
              prefixText: '$currency ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          WedButton(label: 'Add Item', onPressed: onAddCustomItem),
          if (customItems.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Custom items', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            ...customItems.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(item.name, style: AppTextStyles.bodyMedium)),
                      Text('$currency ${item.amount.toStringAsFixed(0)}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondary)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _AllocationReviewStep extends StatelessWidget {
  final BudgetState budgetState;
  const _AllocationReviewStep({required this.budgetState});

  @override
  Widget build(BuildContext context) {
    if (budgetState.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(budgetState.errorMessage ?? 'Unable to generate budget. Please try again.',
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (budgetState.budget == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentBudget = budgetState.budget!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('AI Budget Allocation', style: AppTextStyles.displaySmall),
        const SizedBox(height: 8),
        Text('Your budget has been automatically divided across your selected wedding services.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review your allocation', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 12),
              Text('Total budget: ${currentBudget.currency} ${currentBudget.totalAmount.toStringAsFixed(0)}', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              Text('Remaining contingency: ${currentBudget.currency} ${currentBudget.remainingBudget.toStringAsFixed(0)}',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...currentBudget.categories.map((cat) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AllocationRow(
                cat: cat,
                totalBudget: currentBudget.totalAmount,
                currency: currentBudget.currency,
              ),
            )),
      ],
    );
  }
}

class _AllocationRow extends StatelessWidget {
  final BudgetCategory cat;
  final double totalBudget;
  final String currency;
  const _AllocationRow({
    required this.cat,
    required this.totalBudget,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final pct = totalBudget > 0 ? (cat.allocatedAmount / totalBudget * 100).toStringAsFixed(0) : '0';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Text(cat.categoryIcon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.categoryName, style: AppTextStyles.titleMedium),
                if (cat.aiJustification != null)
                  Text(cat.aiJustification!,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$currency ${cat.allocatedAmount.toStringAsFixed(0)}',
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.secondary)),
              Text('$pct%', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
