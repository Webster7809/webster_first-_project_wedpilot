import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/checklist_item.dart';
import '../core/services/task_service.dart';
import '../core/constants/app_constants.dart';

export '../core/services/task_service.dart' show TaskReportData;

class TaskNotifier extends StateNotifier<List<ChecklistItem>> {
  TaskNotifier() : super(defaultChecklist);

  // ── Add ──────────────────────────────────────────────────────────────────────

  String? addTask({
    required String taskName,
    required String phase,
    DateTime? dueDate,
  }) {
    final error = TaskService.validateTask(
      taskName: taskName,
      phase: phase,
      dueDate: dueDate,
      existingTasks: state,
    );
    if (error != null) return error;

    final id = 'task-${DateTime.now().millisecondsSinceEpoch}';
    state = [
      ...state,
      ChecklistItem(
        id: id,
        coupleId: 'profile-001',
        phase: phase,
        task: taskName.trim(),
        isCompleted: false,
        dueDate: dueDate,
      ),
    ];
    return null;
  }

  // ── Edit ─────────────────────────────────────────────────────────────────────

  String? editTask({
    required String id,
    required String taskName,
    required String phase,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    final error = TaskService.validateTask(
      taskName: taskName,
      phase: phase,
      dueDate: dueDate,
      existingTasks: state,
      excludeId: id,
    );
    if (error != null) return error;

    state = state.map((t) {
      if (t.id != id) return t;
      return t.copyWith(
        task: taskName.trim(),
        phase: phase,
        dueDate: dueDate,
        clearDueDate: clearDueDate,
      );
    }).toList();
    return null;
  }

  // ── Delete ───────────────────────────────────────────────────────────────────

  void deleteTask(String id) {
    state = state.where((t) => t.id != id).toList();
  }

  // ── Toggle completion ────────────────────────────────────────────────────────

  void toggleComplete(String id) {
    state = state.map((t) {
      if (t.id != id) return t;
      return t.copyWith(isCompleted: !t.isCompleted);
    }).toList();
  }

  void markPhaseComplete(String phase) {
    state = state.map((t) {
      if (t.phase != phase) return t;
      return t.copyWith(isCompleted: true);
    }).toList();
  }

  void markPhaseIncomplete(String phase) {
    state = state.map((t) {
      if (t.phase != phase) return t;
      return t.copyWith(isCompleted: false);
    }).toList();
  }

  // ── Report ───────────────────────────────────────────────────────────────────

  TaskReportData generateReport() => TaskService.buildReport(state);
}

// ── Providers ────────────────────────────────────────────────────────────────

final taskProvider = StateNotifierProvider<TaskNotifier, List<ChecklistItem>>(
  (ref) => TaskNotifier(),
);

final taskProgressProvider = Provider<double>((ref) {
  return TaskService.overallProgress(ref.watch(taskProvider));
});

final taskPhaseProgressProvider = Provider<Map<String, double>>((ref) {
  return TaskService.progressByPhase(ref.watch(taskProvider));
});

/// All planning phases in order.
final taskPhasesProvider = Provider<List<String>>((ref) {
  return AppConstants.planningChecklistPhases;
});
