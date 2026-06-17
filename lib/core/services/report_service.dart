import '../../models/budget.dart';
import '../../models/checklist_item.dart';
import '../../models/invitation.dart';
import '../../models/vendor_profile.dart' hide VendorService;
import 'budget_service.dart';
import 'rsvp_service.dart';
import 'task_service.dart';
import 'vendor_service.dart';

/// Orchestrates report generation across all four domains.
class ReportService {
  ReportService._();

  static BudgetReportData generateBudgetReport(Budget budget) {
    final summary = BudgetService.generateSummary(budget);

    final categorySummaries = budget.categories.map((c) {
      final catExpenses =
          budget.expenses.where((e) => e.categoryName == c.categoryName).toList();
      return CategoryExpenseSummary(
        categoryName: c.categoryName,
        categoryIcon: c.categoryIcon,
        allocated: c.allocatedAmount,
        spent: c.spentAmount,
        remaining: c.remainingAmount,
        spendingPercent: c.spendingPercent,
        isOverBudget: c.isOverBudget,
        isNearLimit: c.isNearLimit,
        expenseCount: catExpenses.length,
        expenses: catExpenses,
      );
    }).toList()
      ..sort((a, b) => b.spent.compareTo(a.spent));

    return BudgetReportData(
      summary: summary,
      categorySummaries: categorySummaries,
      generatedAt: DateTime.now(),
    );
  }

  static RsvpReportData generateRsvpReport(
    List<RsvpResponse> responses,
    List<Guest> guests,
  ) {
    final stats = RsvpService.calculateStats(responses, guests);

    final relationBreakdown = <String, int>{};
    for (final g in guests) {
      final rel = g.relation ?? 'Other';
      relationBreakdown[rel] = (relationBreakdown[rel] ?? 0) + 1;
    }

    return RsvpReportData(
      stats: stats,
      guests: guests,
      responses: responses,
      relationBreakdown: relationBreakdown,
      generatedAt: DateTime.now(),
    );
  }

  static VendorReportData generateVendorReport(
    List<VendorProfile> vendors,
    double? totalBudget,
  ) =>
      VendorService.buildReport(vendors, totalBudget);

  static TaskReportData generateTaskReport(List<ChecklistItem> tasks) =>
      TaskService.buildReport(tasks);
}

// ── Budget report ─────────────────────────────────────────────────────────────

class BudgetReportData {
  final BudgetSummary summary;
  final List<CategoryExpenseSummary> categorySummaries;
  final DateTime generatedAt;

  const BudgetReportData({
    required this.summary,
    required this.categorySummaries,
    required this.generatedAt,
  });
}

class CategoryExpenseSummary {
  final String categoryName;
  final String categoryIcon;
  final double allocated;
  final double spent;
  final double remaining;
  final double spendingPercent;
  final bool isOverBudget;
  final bool isNearLimit;
  final int expenseCount;
  final List<Expense> expenses;

  const CategoryExpenseSummary({
    required this.categoryName,
    required this.categoryIcon,
    required this.allocated,
    required this.spent,
    required this.remaining,
    required this.spendingPercent,
    required this.isOverBudget,
    required this.isNearLimit,
    required this.expenseCount,
    required this.expenses,
  });
}

// ── RSVP report ──────────────────────────────────────────────────────────────

class RsvpReportData {
  final RsvpStats stats;
  final List<Guest> guests;
  final List<RsvpResponse> responses;
  final Map<String, int> relationBreakdown;
  final DateTime generatedAt;

  const RsvpReportData({
    required this.stats,
    required this.guests,
    required this.responses,
    required this.relationBreakdown,
    required this.generatedAt,
  });
}
