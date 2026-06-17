import '../../models/budget.dart';
import '../constants/app_constants.dart';

class BudgetService {
  BudgetService._();

  // ── Validation ──────────────────────────────────────────────────────────────

  static String? validateExpense({
    required String categoryName,
    required String amountText,
    required String description,
    required Budget budget,
  }) {
    if (categoryName.isEmpty) return 'Select a budget category.';
    if (amountText.isEmpty) return 'Enter an amount.';
    final amount = double.tryParse(amountText);
    if (amount == null) return 'Enter a valid number.';
    if (amount <= 0) return 'Amount must be greater than zero.';
    if (amount > 100000000) return 'Amount is unrealistically large.';
    if (description.trim().isEmpty) return 'Description is required.';
    if (description.trim().length < 3) return 'Description must be at least 3 characters.';

    final categoryExists = budget.categories.any((c) => c.categoryName == categoryName);
    if (!categoryExists) return 'Selected category does not exist in this budget.';

    return null;
  }

  static String? validateAllocation({
    required String categoryName,
    required double newAmount,
    required Budget budget,
  }) {
    if (newAmount < 0) return 'Allocation cannot be negative.';
    final category =
        budget.categories.where((c) => c.categoryName == categoryName).firstOrNull;
    if (category == null) return 'Category not found.';
    if (newAmount < category.spentAmount) {
      return 'Cannot allocate less than already spent '
          '(${budget.currency} ${category.spentAmount.toStringAsFixed(2)}).';
    }
    return null;
  }

  // ── Expense CRUD ────────────────────────────────────────────────────────────

  static Budget addExpense(Budget budget, Expense expense) {
    final updatedCategories = budget.categories.map((c) {
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

    return _copyBudgetWith(
      budget,
      categories: updatedCategories,
      expenses: [...budget.expenses, expense],
    );
  }

  static Budget removeExpense(Budget budget, String expenseId) {
    final expense = budget.expenses.where((e) => e.id == expenseId).firstOrNull;
    if (expense == null) return budget;

    final updatedCategories = budget.categories.map((c) {
      if (c.categoryName == expense.categoryName) {
        return BudgetCategory(
          id: c.id,
          budgetId: c.budgetId,
          categoryName: c.categoryName,
          categoryIcon: c.categoryIcon,
          allocatedAmount: c.allocatedAmount,
          spentAmount: (c.spentAmount - expense.amount).clamp(0.0, double.infinity),
          aiJustification: c.aiJustification,
        );
      }
      return c;
    }).toList();

    return _copyBudgetWith(
      budget,
      categories: updatedCategories,
      expenses: budget.expenses.where((e) => e.id != expenseId).toList(),
    );
  }

  // ── Category management ─────────────────────────────────────────────────────

  static Budget updateCategoryAllocation(
      Budget budget, String categoryName, double newAmount) {
    final updatedCategories = budget.categories.map((c) {
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

    return _copyBudgetWith(budget, categories: updatedCategories);
  }

  // ── Summary ─────────────────────────────────────────────────────────────────

  static BudgetSummary generateSummary(Budget budget) {
    final overBudgetCats =
        budget.categories.where((c) => c.isOverBudget).map((c) => c.categoryName).toList();
    final nearLimitCats = budget.categories
        .where((c) => c.isNearLimit && !c.isOverBudget)
        .map((c) => c.categoryName)
        .toList();

    final topSpending = budget.categories.isEmpty
        ? null
        : budget.categories.reduce((a, b) => a.spentAmount > b.spentAmount ? a : b);

    final largestExpense = budget.expenses.isEmpty
        ? null
        : budget.expenses.reduce((a, b) => a.amount > b.amount ? a : b);

    final categoryBreakdown = {
      for (final c in budget.categories)
        c.categoryName: CategoryStat(
          allocated: c.allocatedAmount,
          spent: c.spentAmount,
          remaining: c.remainingAmount,
          percent: c.spendingPercent,
          isOverBudget: c.isOverBudget,
          isNearLimit: c.isNearLimit,
        )
    };

    return BudgetSummary(
      totalBudget: budget.totalAmount,
      totalSpent: budget.totalSpent,
      totalRemaining: budget.remainingBudget,
      totalAllocated: budget.totalAllocated,
      spendingPercent: budget.spendingPercentage,
      expenseCount: budget.expenses.length,
      categoryCount: budget.categories.length,
      overBudgetCategories: overBudgetCats,
      nearLimitCategories: nearLimitCats,
      topSpendingCategory: topSpending?.categoryName,
      largestExpenseDescription: largestExpense?.description,
      largestExpenseAmount: largestExpense?.amount,
      currency: budget.currency,
      categoryBreakdown: categoryBreakdown,
    );
  }

  // ── Auto-allocation from template ───────────────────────────────────────────

  static Budget createFromTemplate({
    required double total,
    required String currency,
    List<String>? serviceCategories,
    List<BudgetCustomItem>? customItems,
  }) {
    final selectedCategories = (serviceCategories == null || serviceCategories.isEmpty)
        ? AppConstants.defaultBudgetAllocation.keys.toList()
        : serviceCategories;
    final customEntries = customItems ?? [];
    final customTotal = customEntries.fold<double>(0.0, (sum, i) => sum + i.amount);

    final weights = selectedCategories
        .map((n) => AppConstants.defaultBudgetAllocation[n] ?? 0.05)
        .toList();
    final totalWeight = weights.fold(0.0, (s, w) => s + w);
    final remaining = (total - customTotal).clamp(0.0, total);
    final scale = totalWeight > 0 ? remaining / totalWeight : 0.0;

    final categories = <BudgetCategory>[
      for (int i = 0; i < selectedCategories.length; i++)
        BudgetCategory(
          id: 'cat-${selectedCategories[i].toLowerCase().replaceAll(' ', '-')}',
          budgetId: 'budget-001',
          categoryName: selectedCategories[i],
          categoryIcon: _iconFor(selectedCategories[i]),
          allocatedAmount: weights[i] * scale,
          spentAmount: 0,
          aiJustification: AppConstants.budgetAIJustifications[selectedCategories[i]],
        ),
    ];

    if (customTotal > 0) {
      categories.add(BudgetCategory(
        id: 'cat-custom-items',
        budgetId: 'budget-001',
        categoryName: 'Custom Items',
        categoryIcon: '🧾',
        allocatedAmount: customTotal,
        spentAmount: 0,
        aiJustification: 'Special requests and one-off items you added.',
      ));
    }

    final allocated = categories.fold(0.0, (s, c) => s + c.allocatedAmount);
    if (allocated < total) {
      categories.add(BudgetCategory(
        id: 'cat-contingency',
        budgetId: 'budget-001',
        categoryName: 'Contingency',
        categoryIcon: '🛡️',
        allocatedAmount: total - allocated,
        spentAmount: 0,
        aiJustification: 'Reserved for unexpected costs or last-minute upgrades.',
      ));
    }

    return Budget(
      id: 'budget-001',
      coupleId: 'profile-001',
      totalAmount: total,
      currency: currency,
      isAiGenerated: true,
      categories: categories,
      customItems: customEntries,
      expenses: const [],
      createdAt: DateTime.now(),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static String _iconFor(String category) {
    final idx = AppConstants.vendorCategories.indexOf(category);
    return idx >= 0 ? AppConstants.vendorCategoryIcons[idx] : '💰';
  }

  static Budget _copyBudgetWith(
    Budget b, {
    List<BudgetCategory>? categories,
    List<Expense>? expenses,
  }) =>
      Budget(
        id: b.id,
        coupleId: b.coupleId,
        totalAmount: b.totalAmount,
        currency: b.currency,
        isAiGenerated: b.isAiGenerated,
        categories: categories ?? b.categories,
        customItems: b.customItems,
        expenses: expenses ?? b.expenses,
        createdAt: b.createdAt,
      );
}

// ── Data classes returned by generateSummary ─────────────────────────────────

class BudgetSummary {
  final double totalBudget;
  final double totalSpent;
  final double totalRemaining;
  final double totalAllocated;
  final double spendingPercent;
  final int expenseCount;
  final int categoryCount;
  final List<String> overBudgetCategories;
  final List<String> nearLimitCategories;
  final String? topSpendingCategory;
  final String? largestExpenseDescription;
  final double? largestExpenseAmount;
  final String currency;
  final Map<String, CategoryStat> categoryBreakdown;

  const BudgetSummary({
    required this.totalBudget,
    required this.totalSpent,
    required this.totalRemaining,
    required this.totalAllocated,
    required this.spendingPercent,
    required this.expenseCount,
    required this.categoryCount,
    required this.overBudgetCategories,
    required this.nearLimitCategories,
    required this.topSpendingCategory,
    required this.largestExpenseDescription,
    required this.largestExpenseAmount,
    required this.currency,
    required this.categoryBreakdown,
  });

  bool get hasOverBudgetCategories => overBudgetCategories.isNotEmpty;
  bool get hasNearLimitCategories => nearLimitCategories.isNotEmpty;
  bool get isHealthy => !hasOverBudgetCategories && spendingPercent <= 90;
}

class CategoryStat {
  final double allocated;
  final double spent;
  final double remaining;
  final double percent;
  final bool isOverBudget;
  final bool isNearLimit;

  const CategoryStat({
    required this.allocated,
    required this.spent,
    required this.remaining,
    required this.percent,
    required this.isOverBudget,
    required this.isNearLimit,
  });
}
