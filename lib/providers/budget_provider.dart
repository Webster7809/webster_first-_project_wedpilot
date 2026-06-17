import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';
import '../models/couple_profile.dart';
import '../core/services/budget_service.dart';

export '../core/services/budget_service.dart' show BudgetSummary;

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
      errorMessage:
          identical(errorMessage, _absent) ? this.errorMessage : errorMessage as String?,
    );
  }

  bool get isLoading => status == BudgetStatus.loading;
  bool get hasError => status == BudgetStatus.error;
  bool get hasBudget => budget != null;
}

class BudgetNotifier extends StateNotifier<BudgetState> {
  BudgetNotifier() : super(const BudgetState());

  // ── Initialization ──────────────────────────────────────────────────────────

  Future<void> initializeBudgetForProfile(CoupleProfile? profile) async {
    if (profile == null || !profile.hasBudget) return;
    if (state.hasBudget && state.status == BudgetStatus.ready) return;
    await loadBudget(
      total: profile.totalBudget!,
      currency: profile.currency,
    );
  }

  Future<void> loadBudget({
    required double total,
    required String currency,
    List<String>? serviceCategories,
    List<BudgetCustomItem>? customItems,
  }) async {
    state = state.copyWith(status: BudgetStatus.loading, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 250));

    try {
      Budget budget = BudgetService.createFromTemplate(
        total: total,
        currency: currency,
        serviceCategories: serviceCategories,
        customItems: customItems,
      );

      // Seed realistic sample expenses so the dashboard looks populated
      final seeds = _seedExpenses(budget);
      for (final e in seeds) {
        budget = BudgetService.addExpense(budget, e);
      }

      state = state.copyWith(status: BudgetStatus.ready, budget: budget);
    } catch (e) {
      state = state.copyWith(
        status: BudgetStatus.error,
        errorMessage: 'Unable to generate budget. Please try again.',
      );
    }
  }

  // ── Expense CRUD ────────────────────────────────────────────────────────────

  /// Returns a validation error string, or null on success.
  String? addExpense(Expense expense) {
    final budget = state.budget;
    if (budget == null) return 'No active budget found.';

    final error = BudgetService.validateExpense(
      categoryName: expense.categoryName,
      amountText: expense.amount.toString(),
      description: expense.description,
      budget: budget,
    );
    if (error != null) return error;

    state = state.copyWith(
      budget: BudgetService.addExpense(budget, expense),
    );
    return null;
  }

  /// Returns a validation error string, or null on success.
  String? removeExpense(String expenseId) {
    final budget = state.budget;
    if (budget == null) return 'No active budget found.';
    if (budget.expenses.every((e) => e.id != expenseId)) {
      return 'Expense not found.';
    }

    state = state.copyWith(
      budget: BudgetService.removeExpense(budget, expenseId),
    );
    return null;
  }

  // ── Category allocation ─────────────────────────────────────────────────────

  String? updateCategoryAllocation(String categoryName, double newAmount) {
    final budget = state.budget;
    if (budget == null) return 'No active budget found.';

    final error = BudgetService.validateAllocation(
      categoryName: categoryName,
      newAmount: newAmount,
      budget: budget,
    );
    if (error != null) return error;

    state = state.copyWith(
      budget: BudgetService.updateCategoryAllocation(budget, categoryName, newAmount),
    );
    return null;
  }

  // ── Summary ─────────────────────────────────────────────────────────────────

  BudgetSummary? generateSummary() {
    final budget = state.budget;
    if (budget == null) return null;
    return BudgetService.generateSummary(budget);
  }

  void clearBudget() => state = const BudgetState();

  /// Alias kept for backward compatibility with wizard and home screens.
  Future<void> loadMockBudget(
    double total,
    String currency, {
    List<String>? serviceCategories,
    List<BudgetCustomItem>? customItems,
  }) =>
      loadBudget(
        total: total,
        currency: currency,
        serviceCategories: serviceCategories,
        customItems: customItems,
      );

  // ── Seed data ───────────────────────────────────────────────────────────────

  List<Expense> _seedExpenses(Budget budget) {
    final cats = budget.categories.map((c) => c.categoryName).toList();
    final seeds = <Expense>[];

    void add(String category, double amount, String desc) {
      if (cats.contains(category)) {
        seeds.add(Expense(
          id: 'seed-${seeds.length + 1}',
          budgetId: budget.id,
          categoryName: category,
          amount: amount,
          description: desc,
          status: 'paid',
          createdAt: DateTime.now().subtract(Duration(days: seeds.length + 1)),
        ));
      }
    }

    add('Photography', budget.totalAmount * 0.08, 'Photographer deposit — Golden Hour Studio');
    add('Venue', budget.totalAmount * 0.12, 'Venue booking deposit — Grand Ballroom');
    add('Catering', budget.totalAmount * 0.06, 'Catering tasting session');
    add('Florist', budget.totalAmount * 0.03, 'Floral arrangement consultation');

    return seeds;
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>(
  (ref) => BudgetNotifier(),
);

final budgetSummaryProvider = Provider<Map<String, double>?>((ref) {
  final budget = ref.watch(budgetProvider).budget;
  if (budget == null) return null;
  return {
    'total': budget.totalAmount,
    'allocated': budget.totalAllocated,
    'spent': budget.totalSpent,
    'remaining': budget.remainingBudget,
    'spendingPercent': budget.spendingPercentage,
  };
});

final budgetExpensesProvider = Provider<List<Expense>>((ref) {
  return ref.watch(budgetProvider).budget?.expenses ?? [];
});
