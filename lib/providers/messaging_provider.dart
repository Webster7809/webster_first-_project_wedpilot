import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/messaging.dart';
import '../core/services/messaging_api_service.dart';
import 'auth_provider.dart';

final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final token = ref.watch(authProvider.notifier).accessToken;
  if (token == null) return [];
  return MessagingApiService.instance.fetchConversations(token);
});

final chatMessagesProvider =
    StateNotifierProvider.family<ChatNotifier, AsyncValue<List<Message>>, String>(
  (ref, convoId) => ChatNotifier(ref, convoId),
);

class ChatNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  ChatNotifier(this._ref, this.convoId) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _ref;
  final String convoId;

  String? get _token => _ref.read(authProvider.notifier).accessToken;

  Future<void> load() async {
    final token = _token;
    if (token == null) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      final messages = await MessagingApiService.instance.fetchMessages(token, convoId);
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendMessage(String content) async {
    final token = _token;
    if (token == null || content.trim().isEmpty) return;
    try {
      final message = await MessagingApiService.instance.sendMessage(token, convoId, content.trim());
      state = AsyncValue.data([...state.valueOrNull ?? [], message]);
      // The conversation list's last-message preview and unread counts are
      // derived server-side, so refresh it now that this thread has moved.
      _ref.invalidate(conversationsProvider);
    } on MessagingApiException {
      // Leave state as-is; the message simply doesn't appear, which is an
      // honest reflection of "it wasn't actually sent."
    }
  }
}
