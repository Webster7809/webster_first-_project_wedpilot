import 'package:dio/dio.dart';

import '../../models/checklist_item.dart';
import 'api_error.dart';
import 'authenticated_dio.dart';

// Flutter never touches the database directly.
// All calls go through the Node/Express backend.

class TaskApiException implements Exception {
  final String message;
  const TaskApiException(this.message);
}

class TaskApiService {
  TaskApiService._();
  static final TaskApiService instance = TaskApiService._();

  final Dio _dio = buildApiDio();

  Options _auth(String accessToken) =>
      Options(headers: {'Authorization': 'Bearer $accessToken'});

  Future<List<ChecklistItem>> fetchTasks(String accessToken) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/api/tasks', options: _auth(accessToken));
      final data = response.data ?? {};
      return (data['tasks'] as List<dynamic>? ?? [])
          .map((t) => ChecklistItem.fromJson(t as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw TaskApiException(_extractError(e));
    }
  }

  Future<ChecklistItem> createTask(String accessToken, ChecklistItem task) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/tasks',
        data: {
          'phase': task.phase,
          'task': task.task,
          'due_date': task.dueDate?.toIso8601String(),
          'linked_vendor_id': task.linkedVendorId,
        },
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return ChecklistItem.fromJson(data['task'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw TaskApiException(_extractError(e));
    }
  }

  Future<ChecklistItem> updateTask(String accessToken, ChecklistItem task,
      {bool clearDueDate = false}) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/tasks/${task.id}',
        data: {
          'phase': task.phase,
          'task': task.task,
          if (clearDueDate) 'clear_due_date': true,
          if (!clearDueDate) 'due_date': task.dueDate?.toIso8601String(),
        },
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return ChecklistItem.fromJson(data['task'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw TaskApiException(_extractError(e));
    }
  }

  Future<ChecklistItem> toggleTask(String accessToken, String id) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/tasks/$id/toggle',
        options: _auth(accessToken),
      );
      final data = response.data ?? {};
      return ChecklistItem.fromJson(data['task'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw TaskApiException(_extractError(e));
    }
  }

  Future<void> deleteTask(String accessToken, String id) async {
    try {
      await _dio.delete('/api/tasks/$id', options: _auth(accessToken));
    } on DioException catch (e) {
      throw TaskApiException(_extractError(e));
    }
  }

  String _extractError(DioException e) => describeDioError(e);
}
