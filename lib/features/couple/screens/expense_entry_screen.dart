import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/budget.dart';
import '../../../providers/budget_provider.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_text_field.dart';
import '../../../widgets/wed_snack_bar.dart';

class ExpenseEntryScreen extends ConsumerStatefulWidget {
  const ExpenseEntryScreen({super.key});

  @override
  ConsumerState<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends ConsumerState<ExpenseEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = AppConstants.vendorCategories.first;
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _vendorCtrl = TextEditingController();
  bool _isSaving = false;
  String? _globalError;
  Uint8List? _receiptBytes;
  String? _receiptFilename;

  Future<void> _pickReceipt() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _receiptBytes = bytes;
      _receiptFilename = file.name;
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _vendorCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _globalError = null);
    if (!_formKey.currentState!.validate()) return;

    final budget = ref.read(budgetProvider).data;
    if (budget == null) {
      setState(() => _globalError = 'No active budget found. Please set up your budget first.');
      return;
    }

    // Check that the selected category exists in the budget
    final categoryExists =
        budget.categories.any((c) => c.categoryName == _selectedCategory);
    if (!categoryExists) {
      setState(() =>
          _globalError = '"$_selectedCategory" is not in your current budget. '
              'Choose a different category or update your budget.');
      return;
    }

    setState(() => _isSaving = true);

    final expense = Expense(
      id: 'exp-${DateTime.now().millisecondsSinceEpoch}',
      budgetId: budget.id,
      categoryName: _selectedCategory,
      vendorName: _vendorCtrl.text.trim().isEmpty ? null : _vendorCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.replaceAll(',', '')),
      description: _descCtrl.text.trim(),
      status: 'paid',
      createdAt: DateTime.now(),
    );

    final error = await ref.read(budgetProvider.notifier).addExpense(
          expense,
          receiptBytes: _receiptBytes,
          receiptFilename: _receiptFilename,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      setState(() => _globalError = error);
    } else {
      showWedSnackBar(context, 'Expense recorded successfully.', type: SnackType.success);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final budget = ref.watch(budgetProvider).data;
    final budgetCategories = budget?.categories.map((c) => c.categoryName).toList()
        ?? AppConstants.vendorCategories;

    // Keep selected category valid when budget changes
    if (!budgetCategories.contains(_selectedCategory)) {
      _selectedCategory = budgetCategories.first;
    }

    // Show the allocated vs. spent for the selected category
    final selectedCat = budget?.categories
        .where((c) => c.categoryName == _selectedCategory)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Global error banner
              if (_globalError != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppColors.error.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_globalError!,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.error)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Category selector
              Text('Category', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                items: budgetCategories
                    .map((cat) =>
                        DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Select a category.' : null,
              ),

              // Category budget context
              if (selectedCat != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selectedCat.isOverBudget
                        ? AppColors.error.withAlpha(15)
                        : selectedCat.isNearLimit
                            ? AppColors.warning.withAlpha(15)
                            : AppColors.success.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedCat.isOverBudget
                            ? '⚠️ Over budget!'
                            : selectedCat.isNearLimit
                                ? '⚠️ Near limit'
                                : '✅ On track',
                        style: AppTextStyles.caption.copyWith(
                          color: selectedCat.isOverBudget
                              ? AppColors.error
                              : selectedCat.isNearLimit
                                  ? AppColors.warning
                                  : AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${budget!.currency} ${selectedCat.remainingAmount.toStringAsFixed(0)} remaining',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Amount
              WedTextField(
                label: 'Amount *',
                hint: '0.00',
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.attach_money,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter an amount.';
                  final clean = v.replaceAll(',', '');
                  final parsed = double.tryParse(clean);
                  if (parsed == null) return 'Enter a valid number.';
                  if (parsed <= 0) return 'Amount must be greater than zero.';
                  if (parsed > 100000000) return 'Amount is unrealistically large.';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              WedTextField(
                label: 'Description *',
                hint: 'What was this expense for?',
                controller: _descCtrl,
                maxLines: 2,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Description is required.';
                  if (v.trim().length < 3) {
                    return 'Description must be at least 3 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Vendor name (optional)
              WedTextField(
                label: 'Vendor / Payee (optional)',
                hint: 'e.g. Golden Hour Studio',
                controller: _vendorCtrl,
                prefixIcon: Icons.storefront_outlined,
              ),
              const SizedBox(height: 16),

              // Receipt (optional)
              OutlinedButton.icon(
                onPressed: _pickReceipt,
                icon: Icon(_receiptBytes != null
                    ? Icons.check_circle_outline_rounded
                    : Icons.receipt_long_outlined),
                label: Text(_receiptBytes != null
                    ? 'Receipt attached'
                    : 'Attach receipt (optional)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _receiptBytes != null
                      ? AppColors.success
                      : AppColors.textSecondary,
                  side: BorderSide(
                    color: _receiptBytes != null ? AppColors.success : AppColors.divider,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 32),

              // Recent expenses from this category
              if (selectedCat != null && budget != null) ...[
                _CategoryExpenseList(
                  categoryName: _selectedCategory,
                  currency: budget.currency,
                ),
                const SizedBox(height: 24),
              ],

              WedButton(
                label: 'Record Expense',
                onPressed: _save,
                isLoading: _isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryExpenseList extends ConsumerWidget {
  final String categoryName;
  final String currency;

  const _CategoryExpenseList(
      {required this.categoryName, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allExpenses = ref.watch(budgetExpensesProvider);
    final catExpenses = allExpenses
        .where((e) => e.categoryName == categoryName)
        .toList()
        .reversed
        .take(4)
        .toList();

    if (catExpenses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent in $categoryName',
                style: AppTextStyles.labelLarge),
            Text('Tap to delete',
                style: AppTextStyles.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                )),
          ],
        ),
        const SizedBox(height: 8),
        ...catExpenses.map((e) => _ExpenseRow(expense: e, currency: currency)),
      ],
    );
  }
}

class _ExpenseRow extends ConsumerWidget {
  final Expense expense;
  final String currency;

  const _ExpenseRow({required this.expense, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        dense: true,
        title: Text(expense.description,
            style: AppTextStyles.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: expense.vendorName != null
            ? Text(expense.vendorName!,
                style: AppTextStyles.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                ))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$currency ${expense.amount.toStringAsFixed(0)}',
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: AppColors.error),
              onPressed: () async {
                final error =
                    await ref.read(budgetProvider.notifier).removeExpense(expense.id);
                if (!context.mounted) return;
                if (error != null) {
                  showWedSnackBar(context, error, type: SnackType.error);
                } else {
                  showWedSnackBar(context, 'Expense removed.',
                      type: SnackType.info);
                }
              },
              tooltip: 'Remove expense',
            ),
          ],
        ),
      ),
    );
  }
}
