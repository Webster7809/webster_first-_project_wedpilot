import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';

import '../../models/checklist_item.dart';

// Flutter never touches the database directly.
// All calls go through the Node/Express backend at [_baseUrl].
// Change [_backendPort] or [_lanHost] when deploying to production.
const int _backendPort = 3000;

// Set this to your machine's LAN IP (e.g. '192.168.1.20') when testing on a
// physical device, since 'localhost' on the device refers to the device itself.
const String? _lanHost = null;

String get _baseUrl {
  if (_lanHost != null) return 'http://$_lanHost:$_backendPort';
  if (kIsWeb) return 'http://localhost:$_backendPort';
  if (Platform.isAndroid) return 'http://10.0.2.2:$_backendPort'; // Android emulator → host localhost
  return 'http://localhost:$_backendPort'; // iOS simulator, desktop
}

class TaskApiException implements Exception {
  final String message;
  const TaskApiException(this.message);
}

class TaskApiService {
  TaskApiService._();
  static final TaskApiService instance = TaskApiService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));

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
          'linked_vendor_name': task.linkedVendorName,
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

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return 'Could not reach the server. Please try again.';
  }
}
