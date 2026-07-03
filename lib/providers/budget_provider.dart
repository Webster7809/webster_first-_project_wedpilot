import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget.dart';
import '../models/couple_profile.dart';
import '../core/services/budget_service.dart';
import '../core/services/budget_api_service.dart';
import '../core/state/resource.dart';
import 'auth_provider.dart';

export '../core/services/budget_service.dart' show BudgetSummary;

class BudgetNotifier extends StateNotifier<Resource<Budget>> {
  BudgetNotifier(this._ref) : super(const Resource());

  final Ref _ref;
  final BudgetApiService _service = BudgetApiService.instance;

  String? get _token => _ref.read(authProvider.notifier).accessToken;

  // ── Initialization ──────────────────────────────────────────────────────────

  /// Dashboard path — fetches the couple's existing budget (or lazily
  /// auto-creates one server-side if their profile already has a total set).
  Future<void> initializeBudgetForProfile(CoupleProfile? profile) async {
    if (profile == null || !profile.hasBudget) return;
    if (state.hasData && state.status == ResourceStatus.ready) return;

    final token = _token;
    if (token == null) return;
    state = state.copyWith(status: ResourceStatus.loading);
    try {
      final budget = await _service.fetchBudget(token);
      if (budget == null) {
        state = state.copyWith(status: ResourceStatus.ready);
        return;
      }
      state = state.copyWith(status: ResourceStatus.ready, data: budget);
    } on BudgetApiException catch (e) {
      state = state.copyWith(status: ResourceStatus.error, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        status: ResourceStatus.error,
        errorMessage: 'Could not reach the server. Please try again.',
      );
    }
  }

  /// Wizard path — explicit create/update.
  Future<void> loadBudget({
    required double total,
    required String currency,
    List<String>? serviceCategories,
    List<BudgetCustomItem>? customItems,
  }) async {
    final token = _token;
    if (token == null) {
      state = state.copyWith(status: ResourceStatus.error, errorMessage: 'Not signed in.');
      return;
    }
    state = state.copyWith(status: ResourceStatus.loading, errorMessage: null);
    try {
      final budget = await _service.initBudget(
        token,
        total: total,
        currency: currency,
        serviceCategories: serviceCategories,
        customItems: customItems,
      );
      state = state.copyWith(status: ResourceStatus.ready, data: budget);
    } on BudgetApiException catch (e) {
      state = state.copyWith(status: ResourceStatus.error, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        status: ResourceStatus.error,
        errorMessage: 'Unable to generate budget. Please try again.',
      );
    }
  }

  // ── Expense CRUD ────────────────────────────────────────────────────────────

  /// Returns a validation error string, or null on success.
  Future<String?> addExpense(
    Expense expense, {
    Uint8List? receiptBytes,
    String? receiptFilename,
  }) async {
    final budget = state.data;
    if (budget == null) return 'No active budget found.';

    final error = BudgetService.validateExpense(
      categoryName: expense.categoryName,
      amountText: expense.amount.toString(),
      description: expense.description,
      budget: budget,
    );
    if (error != null) return error;

    final token = _token;
    if (token == null) return 'Not signed in.';

    try {
      final created = await _service.addExpense(
        token,
        categoryName: expense.categoryName,
        amount: expense.amount,
        description: expense.description,
        vendorId: expense.vendorId,
        vendorName: expense.vendorName,
        receiptBytes: receiptBytes,
        receiptFilename: receiptFilename,
      );
      state = state.copyWith(data: BudgetService.addExpense(budget, created));
      return null;
    } on BudgetApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Please try again.';
    }
  }

  /// Returns a validation error string, or null on success.
  Future<String?> removeExpense(String expenseId) async {
    final budget = state.data;
    if (budget == null) return 'No active budget found.';
    if (budget.expenses.every((e) => e.id != expenseId)) {
      return 'Expense not found.';
    }

    final token = _token;
    if (token == null) return 'Not signed in.';

    try {
      await _service.removeExpense(token, expenseId);
      state = state.copyWith(data: BudgetService.removeExpense(budget, expenseId));
      return null;
    } on BudgetApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Please try again.';
    }
  }

  // ── Category allocation ─────────────────────────────────────────────────────

  Future<String?> updateCategoryAllocation(String categoryName, double newAmount) async {
    final budget = state.data;
    if (budget == null) return 'No active budget found.';

    final error = BudgetService.validateAllocation(
      categoryName: categoryName,
      newAmount: newAmount,
      budget: budget,
    );
    if (error != null) return error;

    final token = _token;
    if (token == null) return 'Not signed in.';

    final category = budget.categories.where((c) => c.categoryName == categoryName).firstOrNull;
    if (category == null) return 'Category not found.';

    try {
      await _service.updateCategoryAllocation(token, category.id, newAmount);
      state = state.copyWith(
        data: BudgetService.updateCategoryAllocation(budget, categoryName, newAmount),
      );
      return null;
    } on BudgetApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Please try again.';
    }
  }

  // ── Summary ─────────────────────────────────────────────────────────────────

  BudgetSummary? generateSummary() {
    final budget = state.data;
    if (budget == null) return null;
    return BudgetService.generateSummary(budget);
  }

  void clearBudget() => state = const Resource();
}

// ── Providers ────────────────────────────────────────────────────────────────

final budgetProvider = StateNotifierProvider<BudgetNotifier, Resource<Budget>>(
  (ref) => BudgetNotifier(ref),
);

final budgetSummaryProvider = Provider<Map<String, double>?>((ref) {
  final budget = ref.watch(budgetProvider).data;
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
  return ref.watch(budgetProvider).data?.expenses ?? [];
});
