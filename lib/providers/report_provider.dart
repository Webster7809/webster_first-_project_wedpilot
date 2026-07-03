import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/report_service.dart';
import '../core/services/vendor_service.dart';
import 'budget_provider.dart';
import 'invitation_provider.dart';
import 'task_provider.dart';
import 'vendor_provider.dart';

export '../core/services/report_service.dart';
export '../core/services/vendor_service.dart' show VendorReportData;

class ReportState {
  final BudgetReportData? budgetReport;
  final RsvpReportData? rsvpReport;
  final VendorReportData? vendorReport;
  final TaskReportData? taskReport;
  final bool isGenerating;
  final DateTime? generatedAt;

  const ReportState({
    this.budgetReport,
    this.rsvpReport,
    this.vendorReport,
    this.taskReport,
    this.isGenerating = false,
    this.generatedAt,
  });

  bool get hasReports =>
      budgetReport != null ||
      rsvpReport != null ||
      vendorReport != null ||
      taskReport != null;

  ReportState copyWith({
    BudgetReportData? budgetReport,
    RsvpReportData? rsvpReport,
    VendorReportData? vendorReport,
    TaskReportData? taskReport,
    bool? isGenerating,
    DateTime? generatedAt,
  }) =>
      ReportState(
        budgetReport: budgetReport ?? this.budgetReport,
        rsvpReport: rsvpReport ?? this.rsvpReport,
        vendorReport: vendorReport ?? this.vendorReport,
        taskReport: taskReport ?? this.taskReport,
        isGenerating: isGenerating ?? this.isGenerating,
        generatedAt: generatedAt ?? this.generatedAt,
      );
}

class ReportNotifier extends StateNotifier<ReportState> {
  final Ref _ref;

  ReportNotifier(this._ref) : super(const ReportState());

  void generateAll() {
    state = state.copyWith(isGenerating: true);

    final budget = _ref.read(budgetProvider).data;
    final guestRsvp = _ref.read(guestRsvpProvider);
    final tasks = _ref.read(taskProvider).data ?? [];
    final vendors = _ref.read(allVendorsProvider).valueOrNull ?? [];

    final budgetReport =
        budget != null ? ReportService.generateBudgetReport(budget) : null;

    final rsvpReport = ReportService.generateRsvpReport(
      guestRsvp.responses,
      guestRsvp.guests,
    );

    final vendorReport = ReportService.generateVendorReport(
      vendors,
      budget?.totalAmount,
    );

    final taskReport = ReportService.generateTaskReport(tasks);

    state = ReportState(
      budgetReport: budgetReport,
      rsvpReport: rsvpReport,
      vendorReport: vendorReport,
      taskReport: taskReport,
      isGenerating: false,
      generatedAt: DateTime.now(),
    );
  }

  void generateBudgetReport() {
    final budget = _ref.read(budgetProvider).data;
    if (budget == null) return;
    state = state.copyWith(
      budgetReport: ReportService.generateBudgetReport(budget),
      generatedAt: DateTime.now(),
    );
  }

  void generateRsvpReport() {
    final guestRsvp = _ref.read(guestRsvpProvider);
    state = state.copyWith(
      rsvpReport: ReportService.generateRsvpReport(
        guestRsvp.responses,
        guestRsvp.guests,
      ),
      generatedAt: DateTime.now(),
    );
  }

  void generateVendorReport() {
    final vendors = _ref.read(allVendorsProvider).valueOrNull ?? [];
    final budget = _ref.read(budgetProvider).data;
    state = state.copyWith(
      vendorReport: ReportService.generateVendorReport(vendors, budget?.totalAmount),
      generatedAt: DateTime.now(),
    );
  }

  void generateTaskReport() {
    final tasks = _ref.read(taskProvider).data ?? [];
    state = state.copyWith(
      taskReport: ReportService.generateTaskReport(tasks),
      generatedAt: DateTime.now(),
    );
  }
}

final reportProvider = StateNotifierProvider<ReportNotifier, ReportState>(
  (ref) => ReportNotifier(ref),
);
