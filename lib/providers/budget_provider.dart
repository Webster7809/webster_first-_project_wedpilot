import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';
import '../core/constants/app_constants.dart';

class BudgetNotifier extends StateNotifier<Budget?> {
  BudgetNotifier() : super(null);

  void loadMockBudget(double total, String currency) {
    final categories = AppConstants.defaultBudgetAllocation.entries.map((e) {
      final icons = AppConstants.vendorCategoryIcons;
      final cats = AppConstants.vendorCategories;
      final idx = cats.indexOf(e.key);
      return BudgetCategory(
        id: 'cat-${e.key.toLowerCase().replaceAll(' ', '-')}',
        budgetId: 'budget-001',
        categoryName: e.key,
        categoryIcon: idx >= 0 ? icons[idx] : '💰',
        allocatedAmount: total * e.value,
        spentAmount: total * e.value * 0.3,
        aiJustification: AppConstants.budgetAIJustifications[e.key],
      );
    }).toList();

    state = Budget(
      id: 'budget-001',
      coupleId: 'profile-001',
      totalAmount: total,
      currency: currency,
      isAiGenerated: true,
      categories: categories,
      createdAt: DateTime.now(),
    );
  }

  void updateCategoryAllocation(String categoryName, double newAmount) {
    if (state == null) return;
    final updated = state!.categories.map((c) {
      if (c.categoryName == categoryName) {
        return BudgetCategory(
          id: c.id,
          budgetId: c.budgetId,
          categoryName: c.categoryName,
          categoryIcon: c.categoryIcon,
          allocatedAmount: newAmount,
          spentAmount: c.spentAmount,
          aiJustification: c.aiJustification,
        );
      }
      return c;
    }).toList();
    state = Budget(
      id: state!.id,
      coupleId: state!.coupleId,
      totalAmount: state!.totalAmount,
      currency: state!.currency,
      isAiGenerated: state!.isAiGenerated,
      categories: updated,
      createdAt: state!.createdAt,
    );
  }

  void addExpense(Expense expense) {
    if (state == null) return;
    final updated = state!.categories.map((c) {
      if (c.categoryName == expense.categoryName) {
        return BudgetCategory(
          id: c.id,
          budgetId: c.budgetId,
          categoryName: c.categoryName,
          categoryIcon: c.categoryIcon,
          allocatedAmount: c.allocatedAmount,
          spentAmount: c.spentAmount + expense.amount,
          aiJustification: c.aiJustification,
        );
      }
      return c;
    }).toList();
    state = Budget(
      id: state!.id,
      coupleId: state!.coupleId,
      totalAmount: state!.totalAmount,
      currency: state!.currency,
      isAiGenerated: state!.isAiGenerated,
      categories: updated,
      createdAt: state!.createdAt,
    );
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, Budget?>(
  (ref) => BudgetNotifier(),
);

final budgetSummaryProvider = Provider((ref) {
  final budget = ref.watch(budgetProvider);
  if (budget == null) return null;
  return {
    'total': budget.totalAmount,
    'allocated': budget.totalAllocated,
    'spent': budget.totalSpent,
    'remaining': budget.remainingBudget,
    'spendingPercent': budget.spendingPercentage,
  };
});
