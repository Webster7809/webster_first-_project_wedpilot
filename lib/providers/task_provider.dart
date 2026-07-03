import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/checklist_item.dart';
import '../core/services/task_service.dart';
import '../core/services/task_api_service.dart';
import '../core/constants/app_constants.dart';
import '../core/state/resource.dart';
import 'auth_provider.dart';

export '../core/services/task_service.dart' show TaskReportData;

class TaskNotifier extends StateNotifier<Resource<List<ChecklistItem>>> {
  TaskNotifier(this._ref) : super(const Resource());

  final Ref _ref;
  final TaskApiService _service = TaskApiService.instance;

  String? get _token => _ref.read(authProvider.notifier).accessToken;

  // ── Load ─────────────────────────────────────────────────────────────────────

  Future<void> loadTasks() async {
    final token = _token;
    if (token == null) {
      state = state.copyWith(status: ResourceStatus.error, errorMessage: 'Not signed in.');
      return;
    }
    state = state.copyWith(status: ResourceStatus.loading);
    try {
      final tasks = await _service.fetchTasks(token);
      state = state.copyWith(status: ResourceStatus.ready, data: tasks);
    } on TaskApiException catch (e) {
      state = state.copyWith(status: ResourceStatus.error, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        status: ResourceStatus.error,
        errorMessage: 'Could not reach the server. Please try again.',
      );
    }
  }

  /// Populates the couple's checklist from the curated 24-item planning
  /// template, only when explicitly requested — never auto-seeded.
  Future<String?> loadStarterChecklist() async {
    final token = _token;
    if (token == null) return 'Not signed in.';
    try {
      final created = <ChecklistItem>[];
      for (final item in defaultChecklist) {
        created.add(await _service.createTask(token, item));
      }
      state = state.copyWith(
        status: ResourceStatus.ready,
        data: [...(state.data ?? []), ...created],
      );
      return null;
    } on TaskApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Please try again.';
    }
  }

  // ── Add ──────────────────────────────────────────────────────────────────────

  Future<String?> addTask({
    required String taskName,
    required String phase,
    DateTime? dueDate,
  }) async {
    final error = TaskService.validateTask(
      taskName: taskName,
      phase: phase,
      dueDate: dueDate,
      existingTasks: state.data ?? [],
    );
    if (error != null) return error;

    final token = _token;
    if (token == null) return 'Not signed in.';

    try {
      final created = await _service.createTask(
        token,
        ChecklistItem(
          id: '',
          coupleId: '',
          phase: phase,
          task: taskName.trim(),
          dueDate: dueDate,
        ),
      );
      state = state.copyWith(data: [...(state.data ?? []), created]);
      return null;
    } on TaskApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Please try again.';
    }
  }

  // ── Edit ─────────────────────────────────────────────────────────────────────

  Future<String?> editTask({
    required String id,
    required String taskName,
    required String phase,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) async {
    final error = TaskService.validateTask(
      taskName: taskName,
      phase: phase,
      dueDate: dueDate,
      existingTasks: state.data ?? [],
      excludeId: id,
    );
    if (error != null) return error;

    final token = _token;
    if (token == null) return 'Not signed in.';

    final existing = (state.data ?? []).where((t) => t.id == id).firstOrNull;
    if (existing == null) return 'Task not found.';

    try {
      final updated = await _service.updateTask(
        token,
        existing.copyWith(task: taskName.trim(), phase: phase, dueDate: dueDate, clearDueDate: clearDueDate),
        clearDueDate: clearDueDate,
      );
      state = state.copyWith(
        data: (state.data ?? []).map((t) => t.id == id ? updated : t).toList(),
      );
      return null;
    } on TaskApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Please try again.';
    }
  }

  // ── Delete ───────────────────────────────────────────────────────────────────

  Future<String?> deleteTask(String id) async {
    final token = _token;
    if (token == null) return 'Not signed in.';
    try {
      await _service.deleteTask(token, id);
      state = state.copyWith(data: (state.data ?? []).where((t) => t.id != id).toList());
      return null;
    } on TaskApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Please try again.';
    }
  }

  // ── Toggle completion ────────────────────────────────────────────────────────

  Future<String?> toggleComplete(String id) async {
    final token = _token;
    if (token == null) return 'Not signed in.';
    try {
      final updated = await _service.toggleTask(token, id);
      state = state.copyWith(
        data: (state.data ?? []).map((t) => t.id == id ? updated : t).toList(),
      );
      return null;
    } on TaskApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not reach the server. Please try again.';
    }
  }
}

// ── Providers ────────────────────────────────────────────────────────────────

final taskProvider = StateNotifierProvider<TaskNotifier, Resource<List<ChecklistItem>>>(
  (ref) => TaskNotifier(ref),
);

final taskProgressProvider = Provider<double>((ref) {
  return TaskService.overallProgress(ref.watch(taskProvider).data ?? []);
});

final taskPhaseProgressProvider = Provider<Map<String, double>>((ref) {
  return TaskService.progressByPhase(ref.watch(taskProvider).data ?? []);
});

/// All planning phases in order.
final taskPhasesProvider = Provider<List<String>>((ref) {
  return AppConstants.planningChecklistPhases;
});

/// How many days ahead counts as "due soon" for the in-app reminder banner.
const int taskDueSoonWindowDays = 3;

final tasksDueSoonProvider = Provider<List<ChecklistItem>>((ref) {
  return TaskService.upcomingTasks(
    ref.watch(taskProvider).data ?? [],
    withinDays: taskDueSoonWindowDays,
  );
});
