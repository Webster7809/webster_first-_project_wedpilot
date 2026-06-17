import '../../models/checklist_item.dart';

class TaskService {
  TaskService._();

  // ── Validation ───────────────────────────────────────────────────────────────

  static String? validateTask({
    required String taskName,
    required String phase,
    DateTime? dueDate,
    List<ChecklistItem>? existingTasks,
    String? excludeId,
  }) {
    if (taskName.trim().isEmpty) return 'Task name is required.';
    if (taskName.trim().length < 3) return 'Task name must be at least 3 characters.';
    if (taskName.trim().length > 150) return 'Task name is too long (max 150 characters).';
    if (phase.trim().isEmpty) return 'A planning phase must be selected.';
    if (dueDate != null && dueDate.isBefore(DateTime(2000))) {
      return 'Due date is invalid.';
    }
    if (existingTasks != null) {
      final duplicate = existingTasks.any(
        (t) =>
            t.id != excludeId &&
            t.task.trim().toLowerCase() == taskName.trim().toLowerCase() &&
            t.phase == phase,
      );
      if (duplicate) return 'A task with this name already exists in this phase.';
    }
    return null;
  }

  // ── Progress calculations ────────────────────────────────────────────────────

  static double overallProgress(List<ChecklistItem> tasks) {
    if (tasks.isEmpty) return 0.0;
    return tasks.where((t) => t.isCompleted).length / tasks.length;
  }

  static Map<String, double> progressByPhase(List<ChecklistItem> tasks) {
    final phases = <String, List<ChecklistItem>>{};
    for (final t in tasks) {
      phases.putIfAbsent(t.phase, () => []).add(t);
    }
    return {
      for (final entry in phases.entries)
        entry.key: entry.value.isEmpty
            ? 0.0
            : entry.value.where((t) => t.isCompleted).length /
                entry.value.length,
    };
  }

  static List<ChecklistItem> overdueTasks(List<ChecklistItem> tasks) {
    final now = DateTime.now();
    return tasks
        .where((t) =>
            !t.isCompleted && t.dueDate != null && t.dueDate!.isBefore(now))
        .toList();
  }

  static List<ChecklistItem> upcomingTasks(
    List<ChecklistItem> tasks, {
    int withinDays = 30,
  }) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: withinDays));
    return tasks
        .where((t) =>
            !t.isCompleted &&
            t.dueDate != null &&
            t.dueDate!.isAfter(now) &&
            t.dueDate!.isBefore(cutoff))
        .toList();
  }

  // ── Report ──────────────────────────────────────────────────────────────────

  static TaskReportData buildReport(List<ChecklistItem> tasks) {
    final completed = tasks.where((t) => t.isCompleted).length;
    final overdue = overdueTasks(tasks);
    final upcoming = upcomingTasks(tasks);
    final phaseProgress = progressByPhase(tasks);
    final completedPhases =
        phaseProgress.values.where((p) => p == 1.0).length;

    return TaskReportData(
      totalTasks: tasks.length,
      completedTasks: completed,
      remainingTasks: tasks.length - completed,
      overallProgress: overallProgress(tasks),
      phaseProgress: phaseProgress,
      completedPhases: completedPhases,
      totalPhases: phaseProgress.length,
      overdueTasks: overdue,
      upcomingTasks: upcoming,
    );
  }
}

// ── Data class ───────────────────────────────────────────────────────────────

class TaskReportData {
  final int totalTasks;
  final int completedTasks;
  final int remainingTasks;
  final double overallProgress;
  final Map<String, double> phaseProgress;
  final int completedPhases;
  final int totalPhases;
  final List<ChecklistItem> overdueTasks;
  final List<ChecklistItem> upcomingTasks;

  const TaskReportData({
    required this.totalTasks,
    required this.completedTasks,
    required this.remainingTasks,
    required this.overallProgress,
    required this.phaseProgress,
    required this.completedPhases,
    required this.totalPhases,
    required this.overdueTasks,
    required this.upcomingTasks,
  });

  String get progressLabel =>
      '${(overallProgress * 100).toStringAsFixed(0)}% complete';
}
