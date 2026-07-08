import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';

import '../../models/messaging.dart';

const int _backendPort = 3000;
const String? _lanHost = null;

String get _baseUrl {
  if (_lanHost != null) return 'http://$_lanHost:$_backendPort';
  if (kIsWeb) return 'http://localhost:$_backendPort';
  if (Platform.isAndroid) return 'http://10.0.2.2:$_backendPort';
  return 'http://localhost:$_backendPort';
}

class MessagingApiException implements Exception {
  final String message;
  const MessagingApiException(this.message);
}

class MessagingApiService {
  MessagingApiService._();
  static final MessagingApiService instance = MessagingApiService._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));

  Options _auth(String accessToken) =>
      Options(headers: {'Authorization': 'Bearer $accessToken'});

  /// Returns conversations for whichever role the token belongs to — the
  /// backend resolves couple vs. vendor scoping from the JWT itself.
  Future<List<Conversation>> fetchConversations(String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/messages/conversations', options: _auth(accessToken));
      final list = (response.data?['conversations'] as List?) ?? [];
      return list.map((c) => Conversation.fromJson(c as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw MessagingApiException(_extractError(e));
    }
  }

  /// Find-or-create a conversation with a vendor. Couple-only.
  Future<Conversation> startConversation(String accessToken, String vendorId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/messages/conversations',
        data: {'vendor_id': vendorId},
        options: _auth(accessToken),
      );
      return Conversation.fromJson(response.data?['conversation'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw MessagingApiException(_extractError(e));
    }
  }

  Future<List<Message>> fetchMessages(String accessToken, String convoId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/messages/conversations/$convoId/messages',
        options: _auth(accessToken),
      );
      final list = (response.data?['messages'] as List?) ?? [];
      return list.map((m) => Message.fromJson(m as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw MessagingApiException(_extractError(e));
    }
  }

  Future<Message> sendMessage(String accessToken, String convoId, String content) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/messages/conversations/$convoId/messages',
        data: {'content': content},
        options: _auth(accessToken),
      );
      return Message.fromJson(response.data?['message'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw MessagingApiException(_extractError(e));
    }
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return 'Could not reach the server. Please try again.';
  }
}
