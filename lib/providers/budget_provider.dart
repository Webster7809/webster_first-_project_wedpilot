import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';
import '../core/constants/app_constants.dart';

class BudgetNotifier extends StateNotifier<Budget?> {
  BudgetNotifier() : super(null);

  void loadMockBudget(
    double total,
    String currency, {
    List<String>? serviceCategories,
    List<BudgetCustomItem>? customItems,
  }) {
    final selectedCategories = (serviceCategories == null || serviceCategories.isEmpty)
        ? AppConstants.defaultBudgetAllocation.keys.toList()
        : serviceCategories;
    final customEntries = customItems ?? [];
    final customTotal = customEntries.fold<double>(0.0, (sum, item) => sum + item.amount);

    final categoryWeights = selectedCategories.map((categoryName) {
      return AppConstants.defaultBudgetAllocation[categoryName] ?? 0.05;
    }).toList();
    final totalWeight = categoryWeights.fold(0.0, (sum, weight) => sum + weight);
    final remainingBudget = (total - customTotal).clamp(0.0, total);
    final scale = totalWeight > 0 ? remainingBudget / totalWeight : 0;

    final categories = selectedCategories.map((categoryName) {
      final weight = AppConstants.defaultBudgetAllocation[categoryName] ?? 0.05;
      final allocatedAmount = weight * scale;
      final idx = AppConstants.vendorCategories.indexOf(categoryName);
      return BudgetCategory(
        id: 'cat-${categoryName.toLowerCase().replaceAll(' ', '-')}',
        budgetId: 'budget-001',
        categoryName: categoryName,
        categoryIcon: idx >= 0 ? AppConstants.vendorCategoryIcons[idx] : '💰',
        allocatedAmount: allocatedAmount,
        spentAmount: allocatedAmount * 0.3,
        aiJustification: AppConstants.budgetAIJustifications[categoryName],
      );
    }).toList();

    if (customTotal > 0) {
      categories.add(BudgetCategory(
        id: 'cat-custom-items',
        budgetId: 'budget-001',
        categoryName: 'Custom Items',
        categoryIcon: '🧾',
        allocatedAmount: customTotal,
        spentAmount: 0,
        aiJustification: 'Special requests and one-off wedding items you added.',
      ));
    }

    final allocatedSum = categories.fold(0.0, (sum, category) => sum + category.allocatedAmount);
    if (allocatedSum < total) {
      categories.add(BudgetCategory(
        id: 'cat-contingency',
        budgetId: 'budget-001',
        categoryName: 'Contingency',
        categoryIcon: '🛡️',
        allocatedAmount: total - allocatedSum,
        spentAmount: 0,
        aiJustification: 'Reserved funds for unexpected wedding costs or last-minute upgrades.',
      ));
    }

    state = Budget(
      id: 'budget-001',
      coupleId: 'profile-001',
      totalAmount: total,
      currency: currency,
      isAiGenerated: true,
      categories: categories,
      customItems: customEntries,
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
