import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';
import '../models/couple_profile.dart';
import '../core/constants/app_constants.dart';

enum BudgetStatus { initial, loading, ready, error }

class BudgetState {
  final BudgetStatus status;
  final Budget? budget;
  final String? errorMessage;

  const BudgetState({
    this.status = BudgetStatus.initial,
    this.budget,
    this.errorMessage,
  });

  static const _absent = Object();

  BudgetState copyWith({
    BudgetStatus? status,
    Budget? budget,
    Object? errorMessage = _absent,
  }) {
    return BudgetState(
      status: status ?? this.status,
      budget: budget ?? this.budget,
      errorMessage: identical(errorMessage, _absent) ? this.errorMessage : errorMessage as String?,
    );
  }

  bool get isLoading => status == BudgetStatus.loading;
  bool get hasError => status == BudgetStatus.error;
  bool get hasBudget => budget != null;
}

class BudgetNotifier extends StateNotifier<BudgetState> {
  BudgetNotifier() : super(const BudgetState());

  Future<void> initializeBudgetForProfile(CoupleProfile? profile) async {
    if (profile == null || !profile.hasBudget) return;
    if (state.hasBudget && state.status == BudgetStatus.ready) return;
    await loadMockBudget(profile.totalBudget!, profile.currency);
  }

  Future<void> loadMockBudget(
    double total,
    String currency, {
    List<String>? serviceCategories,
    List<BudgetCustomItem>? customItems,
  }) async {
    state = state.copyWith(status: BudgetStatus.loading, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 250));

    try {
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

      final budget = Budget(
        id: 'budget-001',
        coupleId: 'profile-001',
        totalAmount: total,
        currency: currency,
        isAiGenerated: true,
        categories: categories,
        customItems: customEntries,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(status: BudgetStatus.ready, budget: budget, errorMessage: null);
    } catch (_) {
      state = state.copyWith(
        status: BudgetStatus.error,
        errorMessage: 'Unable to generate budget. Please try again.',
      );
    }
  }

  void updateCategoryAllocation(String categoryName, double newAmount) {
    final currentBudget = state.budget;
    if (currentBudget == null) return;

    final updated = currentBudget.categories.map((c) {
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

    state = state.copyWith(
      status: BudgetStatus.ready,
      budget: Budget(
        id: currentBudget.id,
        coupleId: currentBudget.coupleId,
        totalAmount: currentBudget.totalAmount,
        currency: currentBudget.currency,
        isAiGenerated: currentBudget.isAiGenerated,
        categories: updated,
        customItems: currentBudget.customItems,
        createdAt: currentBudget.createdAt,
      ),
    );
  }

  void addExpense(Expense expense) {
    final currentBudget = state.budget;
    if (currentBudget == null) return;

    final updated = currentBudget.categories.map((c) {
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

    state = state.copyWith(
      status: BudgetStatus.ready,
      budget: Budget(
        id: currentBudget.id,
        coupleId: currentBudget.coupleId,
        totalAmount: currentBudget.totalAmount,
        currency: currentBudget.currency,
        isAiGenerated: currentBudget.isAiGenerated,
        categories: updated,
        customItems: currentBudget.customItems,
        createdAt: currentBudget.createdAt,
      ),
    );
  }

  void clearBudget() {
    state = const BudgetState();
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>(
  (ref) => BudgetNotifier(),
);

final budgetSummaryProvider = Provider<Map<String, double>?>(
  (ref) {
    final budget = ref.watch(budgetProvider).budget;
    if (budget == null) return null;
    return {
      'total': budget.totalAmount,
      'allocated': budget.totalAllocated,
      'spent': budget.totalSpent,
      'remaining': budget.remainingBudget,
      'spendingPercent': budget.spendingPercentage,
    };
  },
);
