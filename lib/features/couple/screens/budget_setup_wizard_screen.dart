import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/budget_provider.dart';
import '../../../widgets/wed_button.dart';

class BudgetSetupWizardScreen extends ConsumerStatefulWidget {
  const BudgetSetupWizardScreen({super.key});

  @override
  ConsumerState<BudgetSetupWizardScreen> createState() => _BudgetSetupWizardScreenState();
}

class _BudgetSetupWizardScreenState extends ConsumerState<BudgetSetupWizardScreen> {
  int _step = 0;
  final _budgetCtrl = TextEditingController(text: '30000');
  String _currency = 'USD';
  int _guestCount = 100;
  final List<String> _priorities = [];
  bool _isGenerating = false;

  @override
  void dispose() {
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateAllocation() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(seconds: 2));
    final total = double.tryParse(_budgetCtrl.text.replaceAll(',', '')) ?? 30000;
    ref.read(budgetProvider.notifier).loadMockBudget(total, _currency);
    setState(() { _isGenerating = false; _step = 2; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Budget Setup — Step ${_step + 1} of 3'),
      ),
      body: Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: List.generate(3, (i) => Expanded(
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
                _Step1(budgetCtrl: _budgetCtrl, currency: _currency,
                    onCurrencyChange: (c) => setState(() => _currency = c)),
                _Step2(guestCount: _guestCount,
                    onGuestCountChange: (v) => setState(() => _guestCount = v),
                    priorities: _priorities,
                    categories: AppConstants.vendorCategories,
                    onPriorityToggle: (c) => setState(() {
                      if (_priorities.contains(c)) {
                        _priorities.remove(c);
                      } else if (_priorities.length < 3) {
                        _priorities.add(c);
                      }
                    })),
                _Step3(budget: ref.watch(budgetProvider)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (_step == 1)
                  WedButton(
                    label: _isGenerating ? 'AI is calculating...' : 'Generate AI Allocation ✨',
                    onPressed: _isGenerating ? null : _generateAllocation,
                    isLoading: _isGenerating,
                  )
                else if (_step == 2)
                  WedButton(
                    label: 'Accept & Start Planning 🎊',
                    onPressed: () => context.go('/couple/dashboard'),
                  )
                else
                  WedButton(
                    label: 'Next',
                    onPressed: () => setState(() => _step++),
                  ),
                if (_step > 0 && _step < 2) ...[
                  const SizedBox(height: 8),
                  WedButton(
                    label: 'Back',
                    variant: WedButtonVariant.ghost,
                    onPressed: () => setState(() => _step--),
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

class _Step1 extends StatelessWidget {
  final TextEditingController budgetCtrl;
  final String currency;
  final ValueChanged<String> onCurrencyChange;

  const _Step1({required this.budgetCtrl, required this.currency, required this.onCurrencyChange});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What\'s your total budget?', style: AppTextStyles.displaySmall),
          const SizedBox(height: 8),
          Text('Enter your total wedding budget. Our AI will allocate it across all categories.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          DropdownButtonFormField<String>(
            initialValue: currency,
            decoration: InputDecoration(
              labelText: 'Currency',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: ['USD', 'EUR', 'GBP', 'CAD', 'AUD', 'NGN', 'KES', 'ZAR']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => onCurrencyChange(v!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: budgetCtrl,
            keyboardType: TextInputType.number,
            style: AppTextStyles.displaySmall.copyWith(color: AppColors.secondary),
            decoration: InputDecoration(
              labelText: 'Total Budget',
              prefixText: '$currency ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          Text('Common budgets:', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['10,000', '20,000', '30,000', '50,000', '75,000', '100,000']
                .map((v) => ActionChip(
                      label: Text('\$$v'),
                      onPressed: () => budgetCtrl.text = v.replaceAll(',', ''),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _Step2 extends StatelessWidget {
  final int guestCount;
  final ValueChanged<int> onGuestCountChange;
  final List<String> priorities;
  final List<String> categories;
  final ValueChanged<String> onPriorityToggle;

  const _Step2({
    required this.guestCount,
    required this.onGuestCountChange,
    required this.priorities,
    required this.categories,
    required this.onPriorityToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Guest count & priorities', style: AppTextStyles.displaySmall),
          const SizedBox(height: 8),
          Text('This helps our AI fine-tune your budget allocation.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          Text('Estimated guest count: $guestCount', style: AppTextStyles.headlineSmall),
          Slider(
            value: guestCount.toDouble(),
            min: 20,
            max: 500,
            divisions: 48,
            label: '$guestCount guests',
            activeColor: AppColors.secondary,
            onChanged: (v) => onGuestCountChange(v.round()),
          ),
          const SizedBox(height: 24),
          Text('Top priorities (choose up to 3):', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 4),
          Text('What matters most for your wedding?',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((cat) {
              final selected = priorities.contains(cat);
              return FilterChip(
                label: Text(cat),
                selected: selected,
                onSelected: (_) => onPriorityToggle(cat),
                selectedColor: AppColors.secondary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.secondary,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _Step3 extends StatelessWidget {
  final dynamic budget;
  const _Step3({this.budget});

  @override
  Widget build(BuildContext context) {
    if (budget == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.info),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Allocation Ready', style: AppTextStyles.titleMedium),
                    Text('Adjust any category below — changes rebalance automatically.',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...budget.categories.map<Widget>((cat) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AllocationRow(cat: cat, totalBudget: budget.totalAmount),
            )),
      ],
    );
  }
}

class _AllocationRow extends StatelessWidget {
  final dynamic cat;
  final double totalBudget;
  const _AllocationRow({required this.cat, required this.totalBudget});

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
              Text('\$${cat.allocatedAmount.toStringAsFixed(0)}',
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.secondary)),
              Text('$pct%', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
