import 'package:dio/dio.dart';

import '../../models/messaging.dart';
import 'api_error.dart';
import 'authenticated_dio.dart';

class MessagingApiException implements Exception {
  final String message;
  const MessagingApiException(this.message);
}

class MessagingApiService {
  MessagingApiService._();
  static final MessagingApiService instance = MessagingApiService._();

  final Dio _dio = buildApiDio();

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

  /// Find-or-create a conversation with a couple. Vendor-only — the backend
  /// requires an inquiry to already exist between the two (see
  /// backend/routes/messaging.js), so this only ever succeeds for a couple
  /// who has actually contacted this vendor.
  Future<Conversation> startConversationWithCouple(
      String accessToken, String coupleUserId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/messages/conversations',
        data: {'couple_user_id': coupleUserId},
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

  String _extractError(DioException e) => describeDioError(e);
}
